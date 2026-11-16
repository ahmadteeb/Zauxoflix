import type { SupabaseClient } from "npm:@supabase/supabase-js@2.119.0";

export class PairingError extends Error {
  constructor(public code: string, public status: number) {
    super(code);
  }
}

export async function sha256(value: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return Array.from(
    new Uint8Array(digest),
    (byte) => byte.toString(16).padStart(2, "0"),
  ).join("");
}

/** Privileged pairing operations. Only narrow service-role RPCs touch private tables. */
export class PairingService {
  constructor(private readonly client: SupabaseClient) {}

  async rateLimit(key: string, attempts: number): Promise<void> {
    const allowed = await this.rpc<boolean>("allow_pairing_request", {
      rate_key: key,
      max_attempts: attempts,
    });
    if (!allowed) throw new PairingError("rate_limited", 429);
  }

  private async rpc<T>(
    name: string,
    params: Record<string, unknown>,
  ): Promise<T> {
    const { data, error } = await this.client.rpc(name, params);
    if (error) throw new PairingError("pairing_unavailable", 503);
    return data as T;
  }

  async start(label: string, ipHash: string) {
    const secret = crypto.randomUUID() + crypto.randomUUID();
    // 32 symbols: a byte maps evenly to the alphabet without modulo bias.
    const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    const code = Array.from(
      crypto.getRandomValues(new Uint8Array(8)),
      (n) => alphabet[n % 32],
    ).join("");
    const expiresAt = await this.rpc<string>("start_tv_pairing", {
      secret: await sha256(secret),
      pairing_code: code,
      device_label: label,
      address_hash: ipHash,
    });
    return { code, deviceSecret: secret, expiresAt, pollIntervalSec: 5 };
  }

  async claim(code: string, token: string) {
    const { data: { user }, error } = await this.client.auth.getUser(token);
    if (error || !user?.email || !user.email_confirmed_at) {
      throw new PairingError("unauthorized", 401);
    }
    await this.rateLimit(`account:${user.id}:claim`, 10);
    const rows = await this.rpc<
      { secret_hash: string; label: string | null }[]
    >("reserve_tv_pairing", {
      pairing_code: code,
      account_id: user.id,
    });
    const pairing = rows[0];
    if (!pairing) throw new PairingError("invalid_pairing_code", 400);
    try {
      const { data, error: linkError } = await this.client.auth.admin
        .generateLink({ type: "magiclink", email: user.email });
      if (linkError) throw new PairingError("pairing_unavailable", 503);
      const saved = await this.rpc<boolean>("finish_tv_pairing", {
        secret: pairing.secret_hash,
        account_id: user.id,
        sign_in_hash: data.properties.hashed_token,
      });
      if (!saved) throw new PairingError("pairing_expired", 400);
    } catch (error) {
      // A failed mint can be retried; a delivered token is never released.
      await this.client.rpc("release_tv_pairing", {
        secret: pairing.secret_hash,
        account_id: user.id,
      });
      throw error;
    }
    return { deviceLabel: pairing.label };
  }

  async poll(secret: string) {
    const secretHash = await sha256(secret);
    await this.rateLimit(`secret:${secretHash}:poll`, 20);
    const tokenHash = await this.rpc<string | null>("consume_tv_pairing", {
      secret: secretHash,
    });
    if (tokenHash) return { status: "claimed", tokenHash };
    const pending = await this.rpc<boolean>("tv_pairing_pending", {
      secret: secretHash,
    });
    if (!pending) throw new PairingError("pairing_expired", 400);
    return { status: "pending" };
  }
}
