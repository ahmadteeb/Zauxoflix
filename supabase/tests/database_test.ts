import { PGlite } from "npm:@electric-sql/pglite@0.3.14";

const alice = "00000000-0000-0000-0000-000000000001";
const bob = "00000000-0000-0000-0000-000000000002";

Deno.test("database migrations and authorization", async (test) => {
  const db = new PGlite();
  const run = async (name: string, sql: string) => {
    await test.step(name, async () => {
      await db.exec("begin");
      try {
        await db.exec(sql);
      } finally {
        await db.exec("rollback");
      }
    });
  };
  try {
    // Mirror Supabase's default grants: tests must catch implicit API access too.
    await db.exec(`
      create role anon;
      create role authenticated;
      create role service_role bypassrls;
      alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
      alter default privileges in schema public grant all on sequences to anon, authenticated, service_role;
      alter default privileges in schema public grant execute on functions to anon, authenticated, service_role;
      create schema auth;
      create table auth.users(id uuid primary key);
      create function auth.uid() returns uuid language sql as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
      grant usage on schema auth to anon, authenticated;
      grant execute on function auth.uid() to anon, authenticated;
      create publication supabase_realtime;
    `);
    const directory = new URL("../migrations/", import.meta.url);
    const files = [];
    for await (const entry of Deno.readDir(directory)) {
      if (entry.name.endsWith(".sql")) files.push(entry.name);
    }
    for (const name of files.sort()) {
      await db.exec(await Deno.readTextFile(new URL(name, directory)));
    }
    await db.exec(`
      insert into auth.users values ('${alice}'), ('${bob}');
      set role authenticated;
      set request.jwt.claim.sub = '${alice}';
      select public.save_source('{"type":"m3u","m3uUrl":"https://example.com/list"}');
      select public.sync_favorite('MOVIE','1');
      select public.sync_progress('MOVIE','1','',20,100,'Movie');
      select public.device_heartbeat('device-alice','linux');
      select public.send_remote_event('device-alice','device-alice','remote','{"action":"pause"}');
      reset role;
    `);
    await run(
      "tables have no Data API resources and RPC reads stay account-scoped",
      `
      do $$ begin
        assert not exists(select 1 from pg_tables where schemaname = 'public'), 'Public table exposed';
        assert not has_schema_privilege('anon','app_data','USAGE'), 'Anonymous schema access';
        assert not has_table_privilege('authenticated','app_data.sources','INSERT'), 'Direct source writes exposed';
      end $$;
      set role authenticated; set request.jwt.claim.sub = '${alice}';
      do $$ begin
        assert public.read_source()->>'type' = 'm3u', 'RPC source read failed';
        assert jsonb_array_length(public.read_favorites()) = 1, 'RPC favorites read failed';
        assert jsonb_array_length(public.read_progress()) = 1, 'RPC progress read failed';
        assert jsonb_array_length(public.read_devices()) = 1, 'RPC device read failed';
        begin perform public.read_favorites(-1,500); raise exception 'Invalid pagination accepted';
        exception when invalid_parameter_value then null; end;
      end $$;
      set request.jwt.claim.sub = '${bob}';
      do $$ begin
        assert public.read_source() is null, 'RPC source leaked';
        assert public.read_favorites() = '[]'::jsonb, 'RPC favorites leaked';
        assert public.read_progress() = '[]'::jsonb, 'RPC progress leaked';
        assert public.read_devices() = '[]'::jsonb, 'RPC devices leaked';
      end $$;
      set role anon;
      do $$ begin
        begin perform public.read_source(); raise exception 'Anonymous RPC read';
        exception when insufficient_privilege then null; end;
        begin perform public.save_source(null); raise exception 'Anonymous RPC write';
        exception when insufficient_privilege then null; end;
      end $$;
    `,
    );
    await run(
      "own account CRUD and durable deletion tombstones",
      `
      set role authenticated; set request.jwt.claim.sub = '${alice}';
      select public.save_source(null);
      select public.sync_favorite('MOVIE','1',true);
      select public.sync_progress('MOVIE','1',removed => true);
      do $$ begin
        assert (select payload is null from app_data.sources), 'Playlist removal lost';
        assert (select "deletedAt" is not null from app_data.favorites), 'Favorite removal lost';
        assert (select "deletedAt" is not null from app_data.watch_progress), 'Progress removal lost';
        begin update app_data.sources set user_id = '${bob}'; raise exception 'Owner reassignment accepted';
        exception when insufficient_privilege then null; end;
        begin delete from app_data.sources; raise exception 'Hard-delete accepted';
        exception when insufficient_privilege then null; end;
        begin update app_data.favorites set "deletedAt" = null; raise exception 'Direct sync write accepted';
        exception when insufficient_privilege then null; end;
      end $$;
    `,
    );
    await run(
      "other accounts cannot select, insert, update or delete private data",
      `
      set role authenticated; set request.jwt.claim.sub = '${bob}';
      do $$ declare changed integer; relation text; hidden boolean; begin
        foreach relation in array array['sources','favorites','watch_progress','devices','remote_events'] loop
          execute format('select count(*) = 0 from app_data.%I', relation) into strict hidden;
          assert hidden, 'Account data leaked';
        end loop;
        begin update app_data.sources set payload = null where user_id = '${alice}';
          raise exception 'Direct update accepted';
        exception when insufficient_privilege then null; end;
        begin insert into app_data.sources values ('${alice}', '{"type":"m3u","m3uUrl":"https://evil.example"}');
          raise exception 'Cross-account insert accepted';
        exception when insufficient_privilege then null; end;
        begin delete from app_data.sources where user_id = '${alice}'; raise exception 'Cross-account delete accepted';
        exception when insufficient_privilege then null; end;
      end $$;
      select public.sync_favorite('MOVIE','2');
      reset role;
      do $$ begin assert (select count(*) = 1 from app_data.favorites where user_id = '${bob}'), 'RPC owner incorrect'; end $$;
    `,
    );
    await run(
      "anonymous access and privileged RPCs are denied",
      `
      do $$ declare role_name text; proc regprocedure; begin
        foreach role_name in array array['anon','authenticated'] loop
          for proc in select p.oid::regprocedure from pg_proc p join pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public' and p.proname in ('start_tv_pairing','reserve_tv_pairing','finish_tv_pairing','release_tv_pairing','consume_tv_pairing','tv_pairing_pending','allow_pairing_request') loop
            assert not has_function_privilege(role_name, proc, 'EXECUTE'), 'Privileged RPC exposed';
          end loop;
          assert not has_schema_privilege(role_name, 'private', 'USAGE'), 'Private schema exposed';
        end loop;
      end $$;
      set role anon;
      do $$ begin
        begin perform public.sync_favorite('MOVIE','1'); raise exception 'Anonymous write accepted';
        exception when insufficient_privilege then null; end;
        begin perform 1 from app_data.sources; raise exception 'Anonymous read accepted';
        exception when insufficient_privilege then null; end;
        begin perform 1 from private.tv_pairings; raise exception 'Secrets exposed';
        exception when insufficient_privilege then null; end;
      end $$;
    `,
    );
    await run(
      "invalid playlist payloads fail instead of bypassing NULL checks",
      `
      set role authenticated; set request.jwt.claim.sub = '${bob}';
      do $$ declare payload jsonb; begin
        foreach payload in array array['{}'::jsonb, '[]'::jsonb, '{"type":"m3u"}'::jsonb, '{"type":"m3u","m3uUrl":42}'::jsonb,
          '{"type":"xtream","serverUrl":"https://provider.example"}'::jsonb] loop
          begin perform public.save_source(payload); raise exception 'Malformed source accepted';
          exception when check_violation then null; end;
        end loop;
      end $$;
    `,
    );
    await run(
      "remote events require a live owned sender and target and valid payload",
      `
      set role authenticated; set request.jwt.claim.sub = '${bob}';
      do $$ begin
        begin perform public.send_remote_event('device-alice','device-alice','remote','{"action":"pause"}');
          raise exception 'Forged sender accepted';
        exception when raise_exception then if sqlerrm <> 'Sender offline' then raise; end if; end;
      end $$;
      select public.device_heartbeat('device-bob','linux');
      do $$ begin
        begin perform public.send_remote_event('device-bob','device-alice','remote','{"action":"pause"}');
          raise exception 'Cross-account command accepted';
        exception when raise_exception then if sqlerrm <> 'Device offline' then raise; end if; end;
        begin perform public.send_remote_event('device-bob','device-bob','remote','{"action":"play"}');
          raise exception 'Invalid identity accepted';
        exception when invalid_parameter_value then null; end;
        begin perform public.send_remote_event('device-bob',null,'remote-status','{"deviceId":"device-alice","state":"playing"}');
          raise exception 'Forged status accepted';
        exception when invalid_parameter_value then null; end;
        begin perform public.send_remote_event('device-bob','device-bob','remote','{"action":"seek","positionSec":"bad"}');
          raise exception 'Invalid position accepted';
        exception when invalid_parameter_value then null; end;
      end $$;
      select public.send_remote_event('device-bob','device-bob','remote','{"action":"play","itemType":"MOVIE","itemId":"1","positionSec":10}');
      select public.send_remote_event('device-bob',null,'remote-status','{"deviceId":"device-bob","state":"playing","positionSec":10,"hasNext":false}');
    `,
    );
    await run(
      "expired events are invisible and only account state is published",
      `
      update app_data.remote_events set expires_at = now() - interval '1 minute';
      set role authenticated; set request.jwt.claim.sub = '${alice}';
      do $$ begin assert (select count(*) = 0 from app_data.remote_events), 'Expired event visible'; end $$;
      reset role;
      do $$ begin
        assert (select count(*) = 4 from pg_publication_tables where pubname = 'supabase_realtime'), 'Publication scope changed';
        assert not exists(select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename not in ('sources','favorites','watch_progress','remote_events')), 'Private data published';
      end $$;
    `,
    );
    await run(
      "service RPCs reserve once, bind the claimant and consume once",
      `
      set role service_role;
      select public.start_tv_pairing(repeat('a',64),'ABCDEFGH','TV',repeat('b',64));
      do $$ begin
        assert (select count(*) = 1 from public.reserve_tv_pairing('ABCDEFGH','${alice}')), 'Claim failed';
        assert (select count(*) = 0 from public.reserve_tv_pairing('ABCDEFGH','${bob}')), 'Second claim accepted';
        assert not public.finish_tv_pairing(repeat('a',64),'${bob}','token'), 'Wrong claimant accepted';
        assert public.finish_tv_pairing(repeat('a',64),'${alice}','token'), 'Token not saved';
        perform public.release_tv_pairing(repeat('a',64),'${alice}');
        assert public.consume_tv_pairing(repeat('a',64)) = 'token', 'Token not delivered';
        assert public.consume_tv_pairing(repeat('a',64)) is null, 'Token replay accepted';
        assert not public.tv_pairing_pending(repeat('a',64)), 'Consumed pairing still live';
        assert public.allow_pairing_request('ip',1), 'First request blocked';
        assert not public.allow_pairing_request('ip',1), 'Rate limit bypassed';
      end $$;
    `,
    );
    await run(
      "failed claims can retry and expired pairings cannot be consumed",
      `
      set role service_role;
      select public.start_tv_pairing(repeat('a',64),'ABCDEFGH','TV',repeat('b',64));
      select public.reserve_tv_pairing('ABCDEFGH','${alice}');
      select public.release_tv_pairing(repeat('a',64),'${bob}');
      do $$ begin assert (select count(*) = 0 from public.reserve_tv_pairing('ABCDEFGH','${bob}')), 'Wrong release accepted'; end $$;
      select public.release_tv_pairing(repeat('a',64),'${alice}');
      select public.reserve_tv_pairing('ABCDEFGH','${bob}');
      select public.finish_tv_pairing(repeat('a',64),'${bob}','token');
      reset role;
      update private.tv_pairings set expires_at = now() - interval '1 minute';
      set role service_role;
      do $$ begin
        assert public.consume_tv_pairing(repeat('a',64)) is null, 'Expired token delivered';
        assert not public.tv_pairing_pending(repeat('a',64)), 'Expired pairing live';
      end $$;
    `,
    );
  } finally {
    await db.close();
  }
});
