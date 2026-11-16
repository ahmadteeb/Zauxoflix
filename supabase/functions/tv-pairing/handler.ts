import { PairingError, type PairingService, sha256 } from "./service.ts";

const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, apikey, content-type, x-client-info",
  "Content-Type": "application/json",
  "Cache-Control": "no-store",
  "X-Content-Type-Options": "nosniff",
};
const reply = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), { status, headers });

type PairingRequest =
  | { action: "start"; deviceLabel: string }
  | { action: "claim"; code: string }
  | { action: "poll"; deviceSecret: string };

async function parseRequest(request: Request): Promise<PairingRequest> {
  if (
    request.headers.get("Content-Type")?.split(";")[0].trim() !==
      "application/json"
  ) {
    throw new PairingError("invalid_request", 415);
  }
  // Bound the stream before decoding, including chunked requests without Content-Length.
  const reader = request.body?.getReader();
  if (!reader) throw new PairingError("invalid_request", 400);
  const chunks: Uint8Array[] = [];
  let size = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      size += value.byteLength;
      if (size > 2048) {
        await reader.cancel();
        throw new PairingError("invalid_request", 413);
      }
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
  }
  const bytes = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.length;
  }
  let body: unknown;
  try {
    body = JSON.parse(new TextDecoder("utf-8", { fatal: true }).decode(bytes));
  } catch {
    throw new PairingError("invalid_request", 400);
  }
  if (!body || typeof body !== "object" || Array.isArray(body)) {
    throw new PairingError("invalid_request", 400);
  }
  const input = body as Record<string, unknown>;
  switch (input.action) {
    case "start": {
      const label = input.deviceLabel ?? "";
      if (typeof label !== "string" || label.length > 100) break;
      return { action: "start", deviceLabel: label.trim() };
    }
    case "claim": {
      if (typeof input.code !== "string" || input.code.length > 32) break;
      const code = input.code.toUpperCase().replace(/[\s-]/g, "");
      if (!/^[A-HJ-NP-Z2-9]{8}$/.test(code)) break;
      return { action: "claim", code };
    }
    case "poll": {
      if (
        typeof input.deviceSecret !== "string" ||
        !/^[a-f0-9-]{72}$/.test(input.deviceSecret)
      ) break;
      return { action: "poll", deviceSecret: input.deviceSecret };
    }
  }
  throw new PairingError("invalid_request", 400);
}

type Service = Pick<PairingService, "start" | "claim" | "poll" | "rateLimit">;
export function createHandler(service: Service) {
  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers });
    }
    if (request.method !== "POST") {
      return reply({ error: "method_not_allowed" }, 405);
    }
    try {
      const body = await parseRequest(request);
      // Also limit claims by verified account and polls by secret in the service.
      const ip =
        request.headers.get("x-forwarded-for")?.split(",").at(-1)?.trim() ||
        "unknown";
      const ipHash = await sha256(ip);
      await service.rateLimit(
        `ip:${ipHash}:${body.action}`,
        body.action === "poll" ? 240 : 10,
      );
      switch (body.action) {
        case "start":
          return reply(await service.start(body.deviceLabel, ipHash));
        case "poll":
          return reply(await service.poll(body.deviceSecret));
        case "claim": {
          const token = /^Bearer ([^\s]+)$/i.exec(
            request.headers.get("Authorization") ?? "",
          )?.[1];
          if (!token) throw new PairingError("unauthorized", 401);
          return reply(await service.claim(body.code, token));
        }
      }
    } catch (error) {
      if (error instanceof PairingError) {
        return reply({ error: error.code }, error.status);
      }
      // Infrastructure failures must not masquerade as invalid user input.
      return reply({ error: "pairing_unavailable" }, 503);
    }
  };
}
