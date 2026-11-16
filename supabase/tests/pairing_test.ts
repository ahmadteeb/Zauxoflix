import { createClient } from "npm:@supabase/supabase-js@2.119.0";
import { createHandler } from "../functions/tv-pairing/handler.ts";
import {
  PairingError,
  PairingService,
} from "../functions/tv-pairing/service.ts";

function assert(value: unknown, message = "Assertion failed"): asserts value {
  if (!value) throw new Error(message);
}
function request(body: unknown, authorization?: string): Request {
  return new Request("https://example.com/tv-pairing", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      ...(authorization ? { authorization } : {}),
    },
    body: JSON.stringify(body),
  });
}
function fakeService() {
  const calls: string[] = [];
  return {
    calls,
    async rateLimit() {
      calls.push("limit");
    },
    async start(label: string) {
      calls.push(`start:${label}`);
      return {
        code: "ABCDEFGH",
        deviceSecret: "secret",
        expiresAt: "2026-11-14T00:00:00Z",
        pollIntervalSec: 5,
      };
    },
    async claim(code: string, token: string) {
      calls.push(`claim:${code}:${token}`);
      return { deviceLabel: "TV" };
    },
    async poll() {
      calls.push("poll");
      return { status: "pending" };
    },
  };
}

Deno.test("HTTP rejects malformed input before privileged operations", async () => {
  const service = fakeService();
  const handler = createHandler(service);
  const invalid: unknown[] = [
    null,
    [],
    {},
    { action: "unknown" },
    { action: "start", deviceLabel: {} },
    { action: "start", deviceLabel: "x".repeat(101) },
    { action: "claim", code: "bad" },
    { action: "poll", deviceSecret: "x".repeat(72) },
  ];
  for (const body of invalid) {
    const response = await handler(request(body));
    assert(response.status === 400);
  }
  assert(service.calls.length === 0);
  assert(
    (await handler(
      new Request("https://example.com", { method: "POST", body: "{}" }),
    )).status === 415,
  );
  const malformed = await handler(
    new Request("https://example.com", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: "{",
    }),
  );
  assert(malformed.status === 400);
});

Deno.test("HTTP bounds chunked body bytes and never caches sign-in tokens", async () => {
  const handler = createHandler(fakeService());
  const stream = new ReadableStream<Uint8Array>({
    start(controller) {
      controller.enqueue(new Uint8Array(2049));
      controller.close();
    },
  });
  const response = await handler(
    new Request("https://example.com", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: stream,
    }),
  );
  assert(response.status === 413);
  const valid = await handler(
    request({ action: "start", deviceLabel: " TV " }),
  );
  assert(
    valid.status === 200 && valid.headers.get("cache-control") === "no-store",
  );
});

Deno.test("HTTP normalizes codes and requires an authenticated claim", async () => {
  const service = fakeService();
  const handler = createHandler(service);
  assert(
    (await handler(request({ action: "claim", code: "abcd-efgh" }))).status ===
      401,
  );
  const response = await handler(
    request({ action: "claim", code: "abcd-efgh" }, "Bearer signed-token"),
  );
  assert(response.status === 200);
  assert(service.calls.includes("claim:ABCDEFGH:signed-token"));
  assert(!service.calls.some((call) => call === "claim:ABCDEFGH:"));
  const preflight = await handler(
    new Request("https://example.com", { method: "OPTIONS" }),
  );
  assert(
    preflight.status === 204 &&
      preflight.headers.get("access-control-allow-methods")?.includes("POST"),
  );
  assert((await handler(new Request("https://example.com"))).status === 405);
});

Deno.test("HTTP distinguishes throttling from infrastructure errors", async () => {
  const service = fakeService();
  service.rateLimit = async () => {
    throw new PairingError("rate_limited", 429);
  };
  assert(
    (await createHandler(service)(request({ action: "start" }))).status === 429,
  );
  service.rateLimit = async () => {
    throw new Error("internal secret");
  };
  const failed = await createHandler(service)(request({ action: "start" }));
  assert(failed.status === 503);
  assert(!(await failed.text()).includes("internal secret"));
});

type Call = { path: string; body: Record<string, unknown> };
function serviceWith(respond: (call: Call) => unknown | Response) {
  const calls: Call[] = [];
  const client = createClient(
    "https://test.supabase.co",
    "service-role-test-key",
    {
      auth: { persistSession: false, autoRefreshToken: false },
      global: {
        fetch: async (input, options) => {
          const path = new URL(
            typeof input === "string"
              ? input
              : input instanceof URL
              ? input.href
              : input.url,
          ).pathname;
          const call = {
            path,
            body: JSON.parse(options?.body as string || "{}") as Record<
              string,
              unknown
            >,
          };
          calls.push(call);
          const data = respond(call);
          return data instanceof Response
            ? data
            : new Response(JSON.stringify(data), {
              headers: { "content-type": "application/json" },
            });
        },
      },
    },
  );
  return { service: new PairingService(client), calls };
}
const confirmedUser = {
  id: "account",
  email: "viewer@example.com",
  email_confirmed_at: "2026-11-14T00:00:00Z",
};

Deno.test("service verifies claims before reserving or minting tokens", async () => {
  const { service, calls } = serviceWith(() =>
    new Response('{"message":"Invalid token"}', { status: 401 })
  );
  try {
    await service.claim("ABCDEFGH", "bad-token");
    throw new Error("Unauthorized claim accepted");
  } catch (error) {
    assert(error instanceof PairingError && error.status === 401);
  }
  assert(calls.length === 1 && calls[0].path === "/auth/v1/user");
});

Deno.test("a lost reservation cannot mint a link", async () => {
  const { service, calls } = serviceWith(({ path }) => {
    if (path === "/auth/v1/user") return confirmedUser;
    if (path.endsWith("allow_pairing_request")) return true;
    if (path.endsWith("reserve_tv_pairing")) return [];
    throw new Error(`Unexpected call: ${path}`);
  });
  try {
    await service.claim("ABCDEFGH", "token");
    throw new Error("Second claim accepted");
  } catch (error) {
    assert(
      error instanceof PairingError && error.code === "invalid_pairing_code",
    );
  }
  assert(!calls.some((call) => call.path.endsWith("generate_link")));
});

Deno.test("token generation failure releases only the reserved claimant", async () => {
  const { service, calls } = serviceWith(({ path }) => {
    if (path === "/auth/v1/user") return confirmedUser;
    if (path.endsWith("allow_pairing_request")) return true;
    if (path.endsWith("reserve_tv_pairing")) {
      return [{ secret_hash: "secret-hash", label: "TV" }];
    }
    if (path.endsWith("generate_link")) {
      return new Response('{"message":"Unavailable"}', { status: 400 });
    }
    if (path.endsWith("release_tv_pairing")) return null;
    throw new Error(`Unexpected call: ${path}`);
  });
  try {
    await service.claim("ABCDEFGH", "token");
    throw new Error("Failed mint accepted");
  } catch (error) {
    assert(error instanceof PairingError && error.status === 503);
  }
  const release = calls.find((call) =>
    call.path.endsWith("release_tv_pairing")
  );
  assert(
    release?.body.secret === "secret-hash" &&
      release.body.account_id === "account",
  );
  assert(!calls.some((call) => call.path.endsWith("finish_tv_pairing")));
});

Deno.test("successful claims save the token without exposing it to the phone", async () => {
  const { service, calls } = serviceWith(({ path }) => {
    if (path === "/auth/v1/user") return confirmedUser;
    if (path.endsWith("allow_pairing_request")) return true;
    if (path.endsWith("reserve_tv_pairing")) {
      return [{ secret_hash: "secret-hash", label: "TV" }];
    }
    if (path.endsWith("generate_link")) {
      return {
        ...confirmedUser,
        hashed_token: "private-token",
        verification_type: "magiclink",
      };
    }
    if (path.endsWith("finish_tv_pairing")) return true;
    throw new Error(`Unexpected call: ${path}`);
  });
  const result = await service.claim("ABCDEFGH", "token");
  assert(
    result.deviceLabel === "TV" &&
      !JSON.stringify(result).includes("private-token"),
  );
  assert(
    calls.find((call) => call.path.endsWith("finish_tv_pairing"))?.body
      .sign_in_hash === "private-token",
  );
});

Deno.test("poll consumes a token through RPC without reading private tables", async () => {
  const { service, calls } = serviceWith(({ path }) => {
    if (path.endsWith("allow_pairing_request")) return true;
    if (path.endsWith("consume_tv_pairing")) return "private-token";
    throw new Error(`Unexpected call: ${path}`);
  });
  const result = await service.poll(crypto.randomUUID() + crypto.randomUUID());
  assert(result.status === "claimed" && result.tokenHash === "private-token");
  assert(calls.every((call) => call.path.startsWith("/rest/v1/rpc/")));
});
