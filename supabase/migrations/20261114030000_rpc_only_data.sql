-- app_data is deliberately absent from PostgREST's exposed schemas.
-- SELECT remains necessary for account-authorized Postgres Changes.
create schema app_data;
revoke all on schema app_data from public, anon;
grant usage on schema app_data to authenticated;
alter table public.sources set schema app_data;
alter table public.favorites set schema app_data;
alter table public.watch_progress set schema app_data;
alter table public.devices set schema app_data;
alter table public.remote_events set schema app_data;
revoke all on all tables in schema app_data from public, anon, authenticated, service_role;
grant select on all tables in schema app_data to authenticated;
drop policy source_insert on app_data.sources;
drop policy source_update on app_data.sources;

-- Existing RPC signatures stay compatible. Rebind their qualified table names
-- after the move; pg_get_functiondef preserves validation, ACLs and search_path.
do $$
declare signature text; definition text; relation text;
begin
  foreach signature in array array[
    'public.sync_favorite(text,text,boolean)',
    'public.sync_progress(text,text,text,integer,integer,text,boolean)',
    'public.device_heartbeat(text,text)',
    'public.send_remote_event(text,text,text,jsonb)'
  ] loop
    definition := pg_get_functiondef(signature::regprocedure);
    foreach relation in array array['sources','favorites','watch_progress','devices','remote_events'] loop
      definition := replace(definition, 'public.' || relation, 'app_data.' || relation);
    end loop;
    execute definition;
  end loop;
end;
$$;

create function public.read_source()
returns jsonb language sql stable security definer set search_path = '' as $$
  select payload from app_data.sources where user_id = auth.uid();
$$;
create function public.save_source(source_payload jsonb)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'Sign in required' using errcode = '42501'; end if;
  insert into app_data.sources(user_id, payload) values(auth.uid(), source_payload)
    on conflict(user_id) do update set payload = excluded.payload;
end;
$$;

create function public.read_favorites(page_offset integer default 0, page_size integer default 500)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
begin
  if page_offset is null or page_offset < 0 or page_size is null or page_size not between 1 and 500 then
    raise exception 'Invalid pagination' using errcode = '22023';
  end if;
  return coalesce((select jsonb_agg(to_jsonb(row)) from (
    select "itemType", "itemId", "createdAt", "deletedAt" from app_data.favorites
    where user_id = auth.uid() order by "itemType", "itemId" limit page_size offset page_offset
  ) row), '[]'::jsonb);
end;
$$;
create function public.read_progress(page_offset integer default 0, page_size integer default 500)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
begin
  if page_offset is null or page_offset < 0 or page_size is null or page_size not between 1 and 500 then
    raise exception 'Invalid pagination' using errcode = '22023';
  end if;
  return coalesce((select jsonb_agg(to_jsonb(row)) from (
    select "itemType", "itemId", "episodeId", "positionSec", "durationSec", subtitle, "updatedAt", "deletedAt"
    from app_data.watch_progress where user_id = auth.uid()
    order by "itemType", "itemId", "episodeId" limit page_size offset page_offset
  ) row), '[]'::jsonb);
end;
$$;
create function public.read_devices()
returns jsonb language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(to_jsonb(row)), '[]'::jsonb) from (
    select "deviceId", platform, "lastSeenAt" from app_data.devices
    where user_id = auth.uid() order by "deviceId"
  ) row;
$$;
revoke all on function public.read_source(), public.save_source(jsonb), public.read_favorites(integer,integer),
  public.read_progress(integer,integer), public.read_devices() from public, anon, service_role;
grant execute on function public.read_source(), public.save_source(jsonb), public.read_favorites(integer,integer),
  public.read_progress(integer,integer), public.read_devices() to authenticated;

-- Moving a published table preserves its publication membership by OID.
-- Prevent future public tables becoming API resources through default grants.
alter default privileges in schema public revoke all on tables from anon, authenticated, service_role;
notify pgrst, 'reload schema';
