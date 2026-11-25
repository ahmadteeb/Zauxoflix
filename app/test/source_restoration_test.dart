import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:zauxoflix/core/router/app_router.dart';
import 'package:zauxoflix/core/widgets/skeleton.dart';
import 'package:zauxoflix/data/backend/auth_models.dart';
import 'package:zauxoflix/data/backend/backend_providers.dart';
import 'package:zauxoflix/data/backend/device_identity.dart';
import 'package:zauxoflix/data/backend/key_value_store.dart';
import 'package:zauxoflix/data/backend/provision_models.dart';
import 'package:zauxoflix/data/backend/provision_repository.dart';
import 'package:zauxoflix/data/backend/realtime_channel.dart';
import 'package:zauxoflix/data/backend/sync_repository.dart';
import 'package:zauxoflix/data/backend/user_cache.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/providers.dart';
import 'package:zauxoflix/features/source_setup/source_setup_screen.dart';

const _user = BackendUser(id: 'account', email: 'viewer@example.com');
const _payload = SourcePayload(
  type: SourceType.m3u,
  serverUrl: 'https://example.test/list.m3u',
  username: '',
  password: '',
);

class _Store implements KeyValueStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

class _Provision extends ProvisionRepository {
  _Provision(super.client, super.db);
  Future<SourcePayload?> response = Future.value(null);
  final requested = Completer<void>();
  @override
  Future<SourcePayload?> fetch() {
    if (!requested.isCompleted) requested.complete();
    return response;
  }
}

class _Realtime extends RealtimeChannel {
  _Realtime(sb.SupabaseClient client)
    : super(
        client,
        const DeviceIdentity(deviceId: 'device', platform: 'linux'),
      );
  late void Function(String, Map<String, dynamic>) onEvent;
  @override
  void start(void Function(String, Map<String, dynamic>) onEvent) {
    this.onEvent = onEvent;
  }

  @override
  void stop() {}
}

class _SyncRepository extends SyncRepository {
  _SyncRepository(super.client, super.db);
  @override
  Future<void> reconcile(int sourceId) async {}
}

class _Sync extends SyncController {
  final entered = Completer<void>();
  final finish = Completer<void>();
  @override
  SyncState build() => const SyncIdle();
  @override
  Future<bool> syncSource(Source source, {bool waitForGuide = true}) async {
    state = const SyncRunning('Loading catalog');
    entered.complete();
    await finish.future;
    await ref.read(databaseProvider).markSynced(source.id);
    state = const SyncSuccess();
    return true;
  }
}

class _ControlledAuth extends AuthController {
  @override
  AuthState build() => const Authenticated(_user, sourceRestoring: true);
  void ready() => state = const Authenticated(_user);
  void fail() => state = const Authenticated(_user, sourceRestoreFailed: true);
}

void main() {
  for (final otherAccount in [false, true]) {
    test(
      'initial catalog stays restoring; previous account cache: $otherAccount',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final client = sb.SupabaseClient('https://example.supabase.co', 'test');
        final store = _Store();
        if (otherAccount) {
          await UserCache(
            store,
          ).save(const BackendUser(id: 'other', email: 'other@example.com'));
          final cachedId = await db.insertSource(_payload.toCompanion());
          await db.markSynced(cachedId);
        }
        final payload = Completer<SourcePayload?>();
        final provision = _Provision(client, db)..response = payload.future;
        final sync = _Sync();
        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            supabaseProvider.overrideWithValue(client),
            keyValueStoreProvider.overrideWithValue(store),
            provisionRepositoryProvider.overrideWithValue(provision),
            realtimeChannelProvider.overrideWithValue(_Realtime(client)),
            syncRepositoryProvider.overrideWithValue(
              _SyncRepository(client, db),
            ),
            syncControllerProvider.overrideWith(() => sync),
          ],
        );
        try {
          final auth = container.read(authControllerProvider.notifier);
          await Future<void>.delayed(Duration.zero);
          final login = auth.completePairing(const LoginResult(user: _user));
          await provision.requested.future;
          expect(
            (container.read(authControllerProvider) as Authenticated)
                .sourceRestoring,
            isTrue,
          );
          payload.complete(_payload);
          await sync.entered.future;
          expect(
            (container.read(authControllerProvider) as Authenticated)
                .sourceRestoring,
            isTrue,
          );
          sync.finish.complete();
          await login;
          final state = container.read(authControllerProvider) as Authenticated;
          expect(state.sourceRestoring, isFalse);
          expect(state.sourceRestoreFailed, isFalse);
        } finally {
          container.dispose();
          await client.dispose();
          await db.close();
        }
      },
    );
  }

  for (final changed in [false, true]) {
    test(
      'cached catalog opens before refresh; changed playlist: $changed',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final client = sb.SupabaseClient('https://example.supabase.co', 'test');
        final store = _Store();
        await UserCache(store).save(_user);
        final sourceId = await db.insertSource(_payload.toCompanion());
        await db.markSynced(sourceId);
        final response = Completer<SourcePayload?>();
        final provision = _Provision(client, db)..response = response.future;
        final sync = _Sync();
        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            supabaseProvider.overrideWithValue(client),
            keyValueStoreProvider.overrideWithValue(store),
            provisionRepositoryProvider.overrideWithValue(provision),
            realtimeChannelProvider.overrideWithValue(_Realtime(client)),
            syncRepositoryProvider.overrideWithValue(
              _SyncRepository(client, db),
            ),
            syncControllerProvider.overrideWith(() => sync),
          ],
        );
        try {
          final auth = container.read(authControllerProvider.notifier);
          await Future<void>.delayed(Duration.zero);
          await auth.completePairing(const LoginResult(user: _user));
          expect(
            (container.read(authControllerProvider) as Authenticated)
                .sourceRestoring,
            isFalse,
          );
          expect(response.isCompleted, isFalse);
          response.complete(
            changed
                ? const SourcePayload(
                    type: SourceType.m3u,
                    serverUrl: 'https://new.example.test/list.m3u',
                    username: '',
                    password: '',
                  )
                : _payload,
          );
          await sync.entered.future;
          expect(
            (container.read(authControllerProvider) as Authenticated)
                .sourceRestoring,
            changed,
          );
          final refreshed = Completer<void>();
          container.listen(authControllerProvider, (_, next) {
            if (next is Authenticated &&
                !next.sourceRestoring &&
                sync.finish.isCompleted &&
                !refreshed.isCompleted) {
              refreshed.complete();
            }
          });
          sync.finish.complete();
          await refreshed.future;
          final state = container.read(authControllerProvider) as Authenticated;
          expect(state.sourceRestoreFailed, isFalse);
          expect(
            (await db.watchActiveSource().first)!.serverUrl,
            changed ? 'https://new.example.test/list.m3u' : _payload.serverUrl,
          );
        } finally {
          container.dispose();
          await client.dispose();
          await db.close();
        }
      },
    );
  }

  test('offline background refresh keeps the cached catalog usable', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final client = sb.SupabaseClient('https://example.supabase.co', 'test');
    final store = _Store();
    await UserCache(store).save(_user);
    final sourceId = await db.insertSource(_payload.toCompanion());
    await db.markSynced(sourceId);
    final response = Completer<SourcePayload?>();
    final provision = _Provision(client, db)..response = response.future;
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        supabaseProvider.overrideWithValue(client),
        keyValueStoreProvider.overrideWithValue(store),
        provisionRepositoryProvider.overrideWithValue(provision),
        realtimeChannelProvider.overrideWithValue(_Realtime(client)),
        syncRepositoryProvider.overrideWithValue(_SyncRepository(client, db)),
      ],
    );
    try {
      final auth = container.read(authControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      await auth.completePairing(const LoginResult(user: _user));
      final refreshed = Completer<void>();
      container.listen(authControllerProvider, (_, next) {
        if (next is Authenticated && !refreshed.isCompleted) {
          refreshed.complete();
        }
      });
      response.completeError(StateError('Network unavailable'));
      await refreshed.future;
      final state = container.read(authControllerProvider) as Authenticated;
      expect(state.sourceRestoring, isFalse);
      expect(state.sourceRestoreFailed, isFalse);
      expect((await db.watchActiveSource().first)!.id, sourceId);
    } finally {
      container.dispose();
      await client.dispose();
      await db.close();
    }
  });

  test(
    'failed source fetch is not an empty account and can be retried',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final client = sb.SupabaseClient('https://example.supabase.co', 'test');
      final response = Completer<SourcePayload?>();
      final provision = _Provision(client, db)..response = response.future;
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          supabaseProvider.overrideWithValue(client),
          keyValueStoreProvider.overrideWithValue(_Store()),
          provisionRepositoryProvider.overrideWithValue(provision),
          realtimeChannelProvider.overrideWithValue(_Realtime(client)),
          syncRepositoryProvider.overrideWithValue(_SyncRepository(client, db)),
        ],
      );
      try {
        final auth = container.read(authControllerProvider.notifier);
        await Future<void>.delayed(Duration.zero);
        final login = auth.completePairing(const LoginResult(user: _user));
        await Future<void>.delayed(Duration.zero);
        response.completeError(StateError('Network unavailable'));
        await login;
        expect(
          (container.read(authControllerProvider) as Authenticated)
              .sourceRestoreFailed,
          isTrue,
        );
        provision.response = Future.value(null);
        await auth.retrySourceRestore();
        final state = container.read(authControllerProvider) as Authenticated;
        expect(state.sourceRestoring, isFalse);
        expect(state.sourceRestoreFailed, isFalse);
        expect(await db.watchActiveSource().first, isNull);
      } finally {
        container.dispose();
        await client.dispose();
        await db.close();
      }
    },
  );

  test(
    'reconnect retries a previously unsynced playlist and clears the Home error',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final client = sb.SupabaseClient('https://example.supabase.co', 'test');
      final failed = Completer<SourcePayload?>();
      final provision = _Provision(client, db)..response = failed.future;
      final realtime = _Realtime(client);
      final sync = _Sync();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          supabaseProvider.overrideWithValue(client),
          keyValueStoreProvider.overrideWithValue(_Store()),
          provisionRepositoryProvider.overrideWithValue(provision),
          realtimeChannelProvider.overrideWithValue(realtime),
          syncRepositoryProvider.overrideWithValue(_SyncRepository(client, db)),
          syncControllerProvider.overrideWith(() => sync),
        ],
      );
      try {
        final auth = container.read(authControllerProvider.notifier);
        await Future<void>.delayed(Duration.zero);
        final login = auth.completePairing(const LoginResult(user: _user));
        await provision.requested.future;
        failed.completeError(StateError('offline'));
        await login;
        expect(
          (container.read(authControllerProvider) as Authenticated)
              .sourceRestoreFailed,
          isTrue,
        );
        final id = await db.insertSource(_payload.toCompanion());
        provision.response = Future.value(_payload);
        final ready = Completer<void>();
        container.listen(authControllerProvider, (_, next) {
          if (next is Authenticated &&
              !next.sourceRestoring &&
              !next.sourceRestoreFailed &&
              !ready.isCompleted) {
            ready.complete();
          }
        });
        realtime.onEvent('provision', {});
        await sync.entered.future;
        sync.finish.complete();
        await ready.future;
        expect((await db.watchActiveSource().first)!.id, id);
        expect((await db.watchActiveSource().first)!.lastSyncAt, isNotNull);
      } finally {
        container.dispose();
        await client.dispose();
        await db.close();
      }
    },
  );

  testWidgets(
    'empty local database shows skeletons until restoration confirms no playlist',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final auth = _ControlledAuth();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          authControllerProvider.overrideWith(() => auth),
          activeSourceProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );
      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SkeletonPulse), findsWidgets);
      expect(find.byType(SourceSetupScreen), findsNothing);
      auth.fail();
      await tester.pump();
      expect(
        find.textContaining('Unable to restore your playlist'),
        findsOneWidget,
      );
      expect(find.byType(SourceSetupScreen), findsNothing);
      auth.ready();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(find.byType(SourceSetupScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await db.close();
    },
  );
}
