-- Internal tables are never exposed through PostgREST or the Realtime publication.
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to service_role;
alter table public.tv_pairings set schema private;
alter table public.pairing_rate_limits set schema private;
revoke all on private.tv_pairings, private.pairing_rate_limits from public, anon, authenticated, service_role;
alter table private.tv_pairings add column claimed_by uuid references auth.users on delete cascade;
create index tv_pairings_expiry on private.tv_pairings(expires_at);
create index pairing_rate_limits_expiry on private.pairing_rate_limits(window_at);

create function public.start_tv_pairing(secret text, pairing_code text, device_label text, address_hash text)
returns timestamptz language plpgsql security definer set search_path = '' as $$
declare expiry timestamptz := now() + interval '5 minutes';
begin
  if secret !~ '^[a-f0-9]{64}$' or pairing_code !~ '^[A-HJ-NP-Z2-9]{8}$'
    or length(address_hash) <> 64 or length(device_label) > 100 then
    raise exception 'Invalid pairing request' using errcode = '22023';
  end if;
  delete from private.tv_pairings where expires_at <= now();
  delete from private.pairing_rate_limits where window_at < now() - interval '1 day';
  insert into private.tv_pairings(secret_hash, code, label, ip_hash, expires_at)
    values(secret, pairing_code, device_label, address_hash, expiry);
  return expiry;
end;
$$;

-- Reserve before generating a sign-in link: two claimants cannot both mint it.
create function public.reserve_tv_pairing(pairing_code text, account_id uuid)
returns table(secret_hash text, label text) language sql security definer set search_path = '' as $$
  update private.tv_pairings set claimed_by = account_id
  where code = pairing_code and expires_at > now() and claimed_by is null and token_hash is null
  returning tv_pairings.secret_hash, tv_pairings.label;
$$;
create function public.finish_tv_pairing(secret text, account_id uuid, sign_in_hash text)
returns boolean language plpgsql security definer set search_path = '' as $$
begin
  if sign_in_hash is null or length(sign_in_hash) not between 1 and 1024 then
    raise exception 'Invalid sign-in token' using errcode = '22023';
  end if;
  update private.tv_pairings set token_hash = sign_in_hash
    where secret_hash = secret and claimed_by = account_id and expires_at > now() and token_hash is null;
  return found;
end;
$$;
create function public.release_tv_pairing(secret text, account_id uuid)
returns void language sql security definer set search_path = '' as $$
  update private.tv_pairings set claimed_by = null
    where secret_hash = secret and claimed_by = account_id and token_hash is null;
$$;

-- Deliver and consume in one statement; clients cannot read the secret table.
create or replace function public.consume_tv_pairing(secret text)
returns text language plpgsql security definer set search_path = '' as $$
declare token text;
begin
  delete from private.tv_pairings where secret_hash = secret and expires_at > now() and token_hash is not null
    returning token_hash into token;
  return token;
end;
$$;
create function public.tv_pairing_pending(secret text)
returns boolean language sql security definer set search_path = '' as $$
  select exists(select 1 from private.tv_pairings where secret_hash = secret and expires_at > now());
$$;
create or replace function public.allow_pairing_request(rate_key text, max_attempts integer)
returns boolean language plpgsql security definer set search_path = '' as $$
declare hits integer;
begin
  if rate_key is null or length(rate_key) not between 1 and 160 or max_attempts not between 1 and 1000 then
    raise exception 'Invalid rate limit' using errcode = '22023';
  end if;
  insert into private.pairing_rate_limits(key, attempts) values(rate_key, 1)
  on conflict(key) do update set
    attempts = case when pairing_rate_limits.window_at < now() - interval '1 minute' then 1 else least(pairing_rate_limits.attempts + 1, max_attempts + 1) end,
    window_at = case when pairing_rate_limits.window_at < now() - interval '1 minute' then now() else pairing_rate_limits.window_at end
  returning attempts into hits;
  return hits <= max_attempts;
end;
$$;

revoke all on function public.start_tv_pairing(text,text,text,text), public.reserve_tv_pairing(text,uuid),
  public.finish_tv_pairing(text,uuid,text), public.release_tv_pairing(text,uuid), public.tv_pairing_pending(text),
  public.consume_tv_pairing(text), public.allow_pairing_request(text,integer) from public, anon, authenticated;
grant execute on function public.start_tv_pairing(text,text,text,text), public.reserve_tv_pairing(text,uuid),
  public.finish_tv_pairing(text,uuid,text), public.release_tv_pairing(text,uuid), public.tv_pairing_pending(text),
  public.consume_tv_pairing(text), public.allow_pairing_request(text,integer) to service_role;
