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
  @override
  Future<SourcePayload?> fetch() => response;
}

class _Realtime extends RealtimeChannel {
  _Realtime(sb.SupabaseClient client)
    : super(
        client,
        const DeviceIdentity(deviceId: 'device', platform: 'linux'),
      );
  @override
  void start(void Function(String, Map<String, dynamic>) onEvent) {}
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
  Future<bool> syncSource(Source source) async {
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
  test(
    'account stays restoring until both playlist fetch and catalog sync finish',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final client = sb.SupabaseClient('https://example.supabase.co', 'test');
      final payload = Completer<SourcePayload?>();
      final provision = _Provision(client, db)..response = payload.future;
      final sync = _Sync();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          supabaseProvider.overrideWithValue(client),
          keyValueStoreProvider.overrideWithValue(_Store()),
          provisionRepositoryProvider.overrideWithValue(provision),
          realtimeChannelProvider.overrideWithValue(_Realtime(client)),
          syncRepositoryProvider.overrideWithValue(_SyncRepository(client, db)),
          syncControllerProvider.overrideWith(() => sync),
        ],
      );
      try {
        final auth = container.read(authControllerProvider.notifier);
        await Future<void>.delayed(Duration.zero);
        final login = auth.completePairing(const LoginResult(user: _user));
        await Future<void>.delayed(const Duration(milliseconds: 20));
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
      router.dispose();
      await db.close();
    },
  );
}
