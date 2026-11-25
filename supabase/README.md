# Supabase architecture

The database owns authorization, identity comes from Supabase Auth, and the Edge Function handles the privileged TV sign-in exchange. Flutter never receives a service-role key.

```text
Flutter ── user JWT ──► public account RPCs ──► unexposed app_data tables
   ▲                            │
   └──── Postgres Changes ───────┘

TV / signed-in phone ──► tv-pairing HTTP handler
                               │ validates body, identity and rate limits
                         PairingService
                               │ service-role-only RPCs
                         private pairing tables
```

## Layout

- `migrations/`: ordered forward migrations. Keep applied migration files unchanged; add a migration for subsequent changes.
- `functions/tv-pairing/index.ts`: environment configuration and server entrypoint.
- `functions/tv-pairing/handler.ts`: bounded HTTP parsing, CORS, authentication header handling, and safe error responses.
- `functions/tv-pairing/service.ts`: verified account claims, reservations, token issuance, and polling through narrow RPCs.
- `tests/database_test.ts`: applies all migrations and exercises authorization with anonymous, two authenticated accounts, and the service role.
- `tests/pairing_test.ts`: HTTP and service behavior with controlled Supabase responses.

## Access rules

| Data | Signed-in account | Mutation boundary | Realtime |
| --- | --- | --- | --- |
| `app_data.sources` | Realtime reads of own row | `read_source` / `save_source`, validated payload | INSERT / UPDATE |
| `app_data.favorites` | Realtime reads of own rows | `read_favorites` / `sync_favorite`, owner derived from JWT | INSERT / UPDATE |
| `app_data.watch_progress` | Realtime reads of own rows | `read_progress` / `sync_progress`, owner derived from JWT | INSERT / UPDATE |
| `app_data.devices` | Own rows only | `read_devices` / `device_heartbeat`, owner derived from JWT | Not published |
| `app_data.remote_events` | Read own unexpired rows | `send_remote_event`, validates sender, target and payload | INSERT |
| `private.tv_pairings` | No access | Service-only pairing RPCs | Never published |
| `private.pairing_rate_limits` | No access | Service-only rate-limit RPC | Never published |

The Data API remains enabled for authenticated RPCs only. No application tables live in the exposed `public` schema. `app_data` and `private` must stay outside the Data API's exposed schemas; adding either to that list would defeat this boundary. Anonymous clients have no table access or account RPC access. Every application table has RLS enabled. Pairing and rate-limit tables have no client policies, schema usage, or client grants. Only the published account tables grant authenticated SELECT for Realtime authorization; they grant no direct client writes.

Account mutation RPCs use a fixed empty search path and derive `user_id` from `auth.uid()`; callers cannot supply another account's ID. Security-definer functions permit narrow writes without granting direct mutations on the sync or command tables. Pairing RPCs accept an account ID only because their execution is restricted to the service role after the Edge Function verifies the user's JWT and confirmed email.

Playlist validation is added with `NOT VALID` to avoid breaking an upgrade that already has malformed legacy rows. New and updated rows are validated immediately. After fixing legacy rows, an operator can run `alter table app_data.sources validate constraint source_payload_valid;`.

## Realtime contract

RLS on the published `app_data` tables authorizes Postgres Changes. Supabase Realtime is independent of the Data API schema allowlist, so an unexposed schema can still deliver authorized account updates. The client also filters on `user_id`; channel names are not an authorization boundary. This implementation uses Postgres Changes, not Broadcast or Presence, so it does not need `realtime.messages` policies.

Playlist removal sets `sources.payload` to SQL NULL. Favorites and progress retain deletion tombstones. These changes arrive as UPDATE events and remain available to disconnected devices during reconciliation. Clients subscribe only to INSERT / UPDATE for durable state and INSERT for remote commands. They never subscribe to DELETE, which avoids relying on deletion-event filtering or authorization.

Remote events expire after 30 seconds and RLS hides expired rows. Both sender and command target must belong to the account and have a heartbeat within 75 seconds. Status payloads must match the sender. Payload validation rejects invalid commands, identities, positions, and transport fields. The client ignores expired commands, its own messages, other targets, and callbacks from a retired session/channel.

A subscription reconnect triggers a fresh account reconciliation. The app also retries periodically while SQLite retains local favorite/progress changes. Remote commands are ephemeral: missed or expired playback commands are not replayed after reconnect.

## Pairing lifecycle

1. A TV starts a five-minute pairing using a cryptographically random private secret and an eight-character code. Only the secret hash is stored.
2. A phone claims the code using a verified, confirmed account. An atomic database UPDATE reserves the pairing before a sign-in token is generated.
3. The Edge Function generates the Supabase magic-link token and stores its hash against that reservation. A failed mint releases only the matching account's unfinished reservation.
4. The TV polls with its private secret. A single atomic DELETE delivers the sign-in hash once; Supabase Auth verifies it and issues the TV session.

Requests are throttled by gateway address, claims additionally by verified account, and polls by secret. Serve the function through the Supabase gateway; forwarded-address limits are not a replacement for JWT or secret verification. Expired pairings and rate-limit windows are pruned during starts. HTTP responses use `Cache-Control: no-store` and never expose internal errors or tokens to the claiming phone.

## Deployment and checks

Zauxoflix 1.1.0 uses the same four Postgres migrations as 1.0.2. If your fork's Supabase project already has all four versions through `20261114030000`, the migration plan should be empty. Earlier installations and new projects apply the missing files in order. Keep the existing migration versions in place.

Use the [Supabase CLI v3](https://supabase.com/docs/reference/cli/introduction) and Python 3 from the repository root. The script targets the project reference you provide, lists its applied migrations, and previews the pending SQL.

```bash
supabase login
python supabase/scripts/update_database.py YOUR_PROJECT_REF
```

After reviewing the plan, apply the pending migrations with `--apply`. For a fresh project or when updating the Edge Function, add `--deploy-pairing`. The script deploys the function after migrations succeed.

```bash
python supabase/scripts/update_database.py YOUR_PROJECT_REF --apply --deploy-pairing
```

The gateway JWT check stays disabled for this function because start/poll run before login. The claim path verifies the bearer JWT itself. Never expose the service key in Flutter or expose `app_data` / `private` in the Data API.

### On-device SQLite upgrade

Flutter upgrades the local library from schema 6 to 13 when the app opens the database. The transaction adds search and discovery indexes and backfills title data, then creates recommendation snapshots, watched-episode tracking, and Live TV viewing, tuning, and guide-link tables. Existing playlists, favorites, playback positions, and downloads remain in place. Back up the device's application-support directory before upgrading if you need a rollback copy. Restoring that backup lets an older app use the library again.

Search history saves separately on the device for each account and playlist. It requires no Supabase table or RPC.

### Local checks

```bash
deno fmt --check supabase/functions supabase/tests
deno check supabase/functions/tv-pairing/index.ts
deno test --allow-read --allow-env --allow-sys supabase/tests/
```

The embedded database tests verify PostgreSQL policies, privileges, constraints and function behavior. A deployed two-account/two-device test is still needed to verify gateway configuration and actual WebSocket delivery.

References: [Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security), [Postgres Changes](https://supabase.com/docs/guides/realtime/postgres-changes), [database functions](https://supabase.com/docs/guides/database/functions).
