-- Preserve existing installs; API signatures and client wire columns stay stable.
-- Playlist removal is an UPDATE so Realtime can authorize it against the owner.
revoke delete on public.sources from authenticated;
drop policy own_sources on public.sources;
create policy source_read on public.sources for select to authenticated
  using ((select auth.uid()) = user_id);
create policy source_insert on public.sources for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy source_update on public.sources for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

alter table public.sources add constraint source_payload_valid check (
  payload is null or coalesce(
    jsonb_typeof(payload) = 'object'
    and octet_length(payload::text) <= 16384
    and (not payload ? 'epgUrl' or payload->'epgUrl' = 'null'::jsonb
      or (jsonb_typeof(payload->'epgUrl') = 'string' and payload->>'epgUrl' ~ '^https?://[^[:space:]]+$'))
    and case payload->>'type'
      when 'm3u' then jsonb_typeof(payload->'m3uUrl') = 'string'
        and payload->>'m3uUrl' ~ '^https?://[^[:space:]]+$'
      when 'xtream' then jsonb_typeof(payload->'serverUrl') = 'string'
        and payload->>'serverUrl' ~ '^https?://[^[:space:]]+$'
        and jsonb_typeof(payload->'username') = 'string'
        and length(payload->>'username') between 1 and 1024
        and jsonb_typeof(payload->'password') = 'string'
        and length(payload->>'password') between 1 and 4096
      else false
    end, false)
) not valid;
-- NOT VALID preserves legacy malformed rows, but rejects new invalid writes.

create index remote_events_account_expiry on public.remote_events(user_id, expires_at);
drop index public.remote_events_account;

-- Expired messages must not be returned by REST or authorized for Realtime.
drop policy own_events on public.remote_events;
create policy own_live_events on public.remote_events for select to authenticated
  using ((select auth.uid()) = user_id and expires_at > now());

create or replace function public.send_remote_event(
  sender_device text, target_device text, event_kind text, event_payload jsonb
) returns void language plpgsql security definer set search_path = '' as $$
declare
  account_id uuid := auth.uid();
  action text := event_payload->>'action';
  field text;
begin
  if account_id is null then raise exception 'Sign in required' using errcode = '42501'; end if;
  if not exists (
    select 1 from public.devices where user_id = account_id and "deviceId" = sender_device
      and "lastSeenAt" > now() - interval '75 seconds'
  ) then raise exception 'Sender offline'; end if;
  if event_kind is null or event_kind not in ('remote', 'remote-status')
    or event_payload is null or jsonb_typeof(event_payload) <> 'object'
    or octet_length(event_payload::text) > 8192 then
    raise exception 'Invalid event' using errcode = '22023';
  end if;
  foreach field in array array['positionSec','durationSec'] loop
    if event_payload ? field and not coalesce(
      jsonb_typeof(event_payload->field) = 'number'
      and event_payload->>field ~ '^[0-9]{1,9}$', false) then
      raise exception 'Invalid position' using errcode = '22023';
    end if;
  end loop;
  foreach field in array array['title','subtitle'] loop
    if event_payload ? field and not coalesce(
      jsonb_typeof(event_payload->field) = 'string' and length(event_payload->>field) <= 1000, false) then
      raise exception 'Invalid label' using errcode = '22023';
    end if;
  end loop;
  foreach field in array array['hasPrev','hasNext'] loop
    if event_payload ? field and jsonb_typeof(event_payload->field) <> 'boolean' then
      raise exception 'Invalid transport state' using errcode = '22023';
    end if;
  end loop;
  if event_payload ? 'itemType' or action = 'play' then
    if not coalesce(
      event_payload->>'itemType' in ('LIVE','MOVIE','SERIES')
      and jsonb_typeof(event_payload->'itemId') = 'string'
      and length(event_payload->>'itemId') between 1 and 128
      and (not event_payload ? 'episodeId' or jsonb_typeof(event_payload->'episodeId') = 'string')
      and (event_payload->>'itemType' <> 'SERIES' or length(event_payload->>'episodeId') between 1 and 128), false) then
      raise exception 'Invalid playback identity' using errcode = '22023';
    end if;
  end if;
  if event_kind = 'remote' then
    if target_device is null or not exists (
      select 1 from public.devices where user_id = account_id and "deviceId" = target_device
        and "lastSeenAt" > now() - interval '75 seconds'
    ) then raise exception 'Device offline'; end if;
    if action is null or action not in ('play','seek','pause','resume','next','prev','stop') then
      raise exception 'Invalid command' using errcode = '22023';
    end if;
    if action = 'seek' and not coalesce(
      jsonb_typeof(event_payload->'positionSec') = 'number'
      and event_payload->>'positionSec' ~ '^[0-9]{1,9}$', false) then
      raise exception 'Invalid seek position' using errcode = '22023';
    end if;
  else
    if target_device is not null or not coalesce(
      event_payload->>'deviceId' = sender_device
      and event_payload->>'state' in ('loading','playing','paused','idle'), false) then
      raise exception 'Invalid status' using errcode = '22023';
    end if;
  end if;
  delete from public.remote_events where user_id = account_id and expires_at <= now();
  insert into public.remote_events(user_id, sender, target, kind, payload)
  values(account_id, sender_device, target_device, event_kind, event_payload);
end;
$$;

-- Only inserts carry commands. Removing remote_events from this publication
-- would also remove command delivery, so the client subscribes to INSERT only.
comment on table public.remote_events is 'Short-lived account-scoped command inbox; subscribe to INSERT only, never DELETE.';
comment on table public.sources is 'One private playlist per account. Null payload is the realtime deletion tombstone.';
