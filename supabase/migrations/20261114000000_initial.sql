-- Free accounts: Supabase Auth owns identity; every row belongs to one account.
create table public.sources (
  user_id uuid primary key references auth.users on delete cascade,
  payload jsonb check (payload is null or (payload->>'type' in ('xtream', 'm3u')))
);
create table public.favorites (
  user_id uuid not null references auth.users on delete cascade,
  "itemType" text not null check ("itemType" in ('LIVE','MOVIE','SERIES')),
  "itemId" text not null check (length("itemId") between 1 and 128),
  "createdAt" timestamptz not null default now(),
  "deletedAt" timestamptz,
  primary key (user_id, "itemType", "itemId")
);
create table public.watch_progress (
  user_id uuid not null references auth.users on delete cascade,
  "itemType" text not null check ("itemType" in ('MOVIE','SERIES')),
  "itemId" text not null check (length("itemId") between 1 and 128),
  "episodeId" text not null default '' check (length("episodeId") <= 128),
  "positionSec" integer not null default 0 check ("positionSec" >= 0),
  "durationSec" integer not null default 0 check ("durationSec" >= 0),
  subtitle text not null default '' check (length(subtitle) <= 1000),
  "updatedAt" timestamptz not null default now(),
  "deletedAt" timestamptz,
  primary key (user_id, "itemType", "itemId", "episodeId")
);
create table public.devices (
  user_id uuid not null references auth.users on delete cascade,
  "deviceId" text not null check (length("deviceId") between 8 and 128),
  platform text check (length(platform) <= 32),
  "lastSeenAt" timestamptz not null default now(),
  primary key (user_id, "deviceId")
);
create table public.remote_events (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users on delete cascade,
  sender text not null,
  target text,
  kind text not null check (kind in ('remote', 'remote-status')),
  payload jsonb not null check (octet_length(payload::text) <= 8192),
  expires_at timestamptz not null default (now() + interval '30 seconds')
);
create index remote_events_account on public.remote_events(user_id);
create index remote_events_expiry on public.remote_events(expires_at);

alter table public.sources enable row level security;
alter table public.favorites enable row level security;
alter table public.watch_progress enable row level security;
alter table public.devices enable row level security;
alter table public.remote_events enable row level security;
create policy own_sources on public.sources for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy own_favorites on public.favorites for select to authenticated using ((select auth.uid()) = user_id);
create policy own_progress on public.watch_progress for select to authenticated using ((select auth.uid()) = user_id);
create policy own_devices on public.devices for select to authenticated using ((select auth.uid()) = user_id);
create policy own_events on public.remote_events for select to authenticated using ((select auth.uid()) = user_id);
revoke all on public.sources, public.favorites, public.watch_progress, public.devices, public.remote_events from anon, authenticated;
grant select, insert, update, delete on public.sources to authenticated;
grant select on public.favorites, public.watch_progress, public.devices, public.remote_events to authenticated;

-- Writes use server time, preserving tombstones for disconnected devices.
create function public.sync_favorite(item_type text, item_id text, removed boolean default false)
returns void language sql security definer set search_path = '' as $$
  insert into public.favorites(user_id, "itemType", "itemId", "createdAt", "deletedAt")
  values (auth.uid(), item_type, item_id, now(), case when removed then now() end)
  on conflict (user_id, "itemType", "itemId") do update
  set "createdAt" = case when removed then favorites."createdAt" else now() end,
      "deletedAt" = case when removed then now() end;
$$;
create function public.sync_progress(item_type text, item_id text, episode_id text default '', position_sec integer default 0, duration_sec integer default 0, label text default '', removed boolean default false)
returns void language sql security definer set search_path = '' as $$
  insert into public.watch_progress(user_id, "itemType", "itemId", "episodeId", "positionSec", "durationSec", subtitle, "updatedAt", "deletedAt")
  values (auth.uid(), item_type, item_id, episode_id, position_sec, duration_sec, label, now(), case when removed then now() end)
  on conflict (user_id, "itemType", "itemId", "episodeId") do update
  set "positionSec" = excluded."positionSec", "durationSec" = excluded."durationSec", subtitle = excluded.subtitle,
      "updatedAt" = now(), "deletedAt" = excluded."deletedAt";
$$;
create function public.device_heartbeat(device_id text, device_platform text)
returns void language sql security definer set search_path = '' as $$
  insert into public.devices(user_id, "deviceId", platform) values(auth.uid(), device_id, device_platform)
  on conflict(user_id, "deviceId") do update set "lastSeenAt" = now(), platform = excluded.platform;
$$;
create function public.send_remote_event(sender_device text, target_device text, event_kind text, event_payload jsonb)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  if event_kind = 'remote' and not exists (
    select 1 from public.devices where user_id = auth.uid() and "deviceId" = target_device and "lastSeenAt" > now() - interval '75 seconds'
  ) then raise exception 'Device offline'; end if;
  if event_kind = 'remote' and coalesce(event_payload->>'action','') not in ('play','seek','pause','resume','next','prev','stop') then
    raise exception 'Invalid command';
  end if;
  delete from public.remote_events where user_id = auth.uid() and expires_at < now();
  insert into public.remote_events(user_id, sender, target, kind, payload)
  values(auth.uid(), sender_device, target_device, event_kind, event_payload);
end;
$$;
revoke all on function public.sync_favorite(text,text,boolean), public.sync_progress(text,text,text,integer,integer,text,boolean), public.device_heartbeat(text,text), public.send_remote_event(text,text,text,jsonb) from public, anon;
grant execute on function public.sync_favorite(text,text,boolean), public.sync_progress(text,text,text,integer,integer,text,boolean), public.device_heartbeat(text,text), public.send_remote_event(text,text,text,jsonb) to authenticated;

alter publication supabase_realtime add table public.sources, public.favorites, public.watch_progress, public.remote_events;

-- Only the Edge Function can access pairing secrets or issue a TV session.
create table public.tv_pairings (
  secret_hash text primary key,
  code text not null unique,
  label text check (length(label) <= 100),
  ip_hash text not null,
  token_hash text,
  expires_at timestamptz not null default (now() + interval '5 minutes'),
  created_at timestamptz not null default now()
);
alter table public.tv_pairings enable row level security;
revoke all on public.tv_pairings from anon, authenticated;
grant select, insert, update, delete on public.tv_pairings to service_role;
create index tv_pairings_ip on public.tv_pairings(ip_hash, created_at);
create function public.consume_tv_pairing(secret text)
returns text language plpgsql security definer set search_path = '' as $$
declare token text;
begin
  delete from public.tv_pairings where secret_hash = secret and expires_at > now() and token_hash is not null returning token_hash into token;
  return token;
end;
$$;
revoke all on function public.consume_tv_pairing(text) from public, anon, authenticated;
grant execute on function public.consume_tv_pairing(text) to service_role;
create table public.pairing_rate_limits (key text primary key, window_at timestamptz not null default now(), attempts integer not null default 0);
alter table public.pairing_rate_limits enable row level security;
revoke all on public.pairing_rate_limits from anon, authenticated;
create function public.allow_pairing_request(rate_key text, max_attempts integer)
returns boolean language plpgsql security definer set search_path = '' as $$
declare hits integer;
begin
  insert into public.pairing_rate_limits(key, attempts) values(rate_key, 1)
  on conflict(key) do update set
    attempts = case when pairing_rate_limits.window_at < now() - interval '1 minute' then 1 else pairing_rate_limits.attempts + 1 end,
    window_at = case when pairing_rate_limits.window_at < now() - interval '1 minute' then now() else pairing_rate_limits.window_at end
  returning attempts into hits;
  return hits <= max_attempts;
end;
$$;
revoke all on function public.allow_pairing_request(text,integer) from public, anon, authenticated;
grant execute on function public.allow_pairing_request(text,integer) to service_role;
