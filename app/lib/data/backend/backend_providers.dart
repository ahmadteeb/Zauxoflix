import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../providers.dart';
import 'auth_models.dart';
import 'auth_repository.dart';
import 'device_identity.dart';
import 'key_value_store.dart';
import 'pairing_repository.dart';
import 'provision_repository.dart';
import 'realtime_channel.dart';
import 'remote_models.dart';
import 'remote_repository.dart';
import 'sync_repository.dart';
import 'user_cache.dart';

final keyValueStoreProvider = Provider<KeyValueStore>(
  (_) => throw UnimplementedError(),
);
final deviceIdentityProvider = Provider<DeviceIdentity>(
  (_) => throw UnimplementedError(),
);
final supabaseProvider = Provider<sb.SupabaseClient>(
  (_) => sb.Supabase.instance.client,
);

/// Public project identity for pairing QR validation; contains no API key.
final pairingProjectProvider = Provider<Uri>(
  (ref) => Uri.parse(Uri.parse(ref.watch(supabaseProvider).rest.url).origin),
);
final userCacheProvider = Provider<UserCache>(
  (ref) => UserCache(ref.watch(keyValueStoreProvider)),
);
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseProvider)),
);
final pairingRepositoryProvider = Provider<PairingRepository>(
  (ref) => PairingRepository(ref.watch(supabaseProvider)),
);
final provisionRepositoryProvider = Provider<ProvisionRepository>(
  (ref) => ProvisionRepository(
    ref.watch(supabaseProvider),
    ref.watch(databaseProvider),
  ),
);
final syncRepositoryProvider = Provider<SyncRepository>(
  (ref) =>
      SyncRepository(ref.watch(supabaseProvider), ref.watch(databaseProvider)),
);
final realtimeChannelProvider = Provider<RealtimeChannel>(
  (ref) => RealtimeChannel(
    ref.watch(supabaseProvider),
    ref.watch(deviceIdentityProvider),
  ),
);
final remoteRepositoryProvider = Provider<RemoteRepository>(
  (ref) => RemoteRepository(
    ref.watch(supabaseProvider),
    ref.watch(deviceIdentityProvider),
  ),
);
final remoteCommandsProvider = Provider<RemoteCommandBus>((ref) {
  final bus = RemoteCommandBus();
  ref.onDispose(bus.dispose);
  return bus;
});

class RemoteCommandBus {
  final _controller = StreamController<RemoteCommand>.broadcast();
  Stream<RemoteCommand> get stream => _controller.stream;
  void emit(RemoteCommand command) => _controller.add(command);
  void dispose() => _controller.close();
}

final remoteStatusProvider =
    NotifierProvider<RemoteStatusController, RemoteStatus?>(
      RemoteStatusController.new,
    );

class RemoteStatusController extends Notifier<RemoteStatus?> {
  @override
  RemoteStatus? build() => null;
  void onEvent(Map<String, dynamic> data) {
    final status = RemoteStatus.parse(data);
    if (status != null) state = status;
  }

  void clear() => state = null;
}

sealed class AuthState {
  const AuthState();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  const Authenticated(
    this.user, {
    this.sourceRestoring = false,
    this.sourceRestoreFailed = false,
  });
  final BackendUser user;
  final bool sourceRestoring;
  final bool sourceRestoreFailed;

  Authenticated withUser(BackendUser user) => Authenticated(
    user,
    sourceRestoring: sourceRestoring,
    sourceRestoreFailed: sourceRestoreFailed,
  );
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  Timer? _timer;
  bool _disposed = false;
  bool _reconciling = false;
  bool _reconcileAgain = false;
  bool _refreshing = false;
  Completer<void>? _refreshDone;
  bool _refreshAgain = false;
  int _generation = 0;

  @override
  AuthState build() {
    final subscription = ref
        .read(supabaseProvider)
        .auth
        .onAuthStateChange
        .listen(
          (event) {
            if (event.event == sb.AuthChangeEvent.signedOut) {
              unawaited(_clearSession());
            } else if (event.event == sb.AuthChangeEvent.userUpdated &&
                state is Authenticated) {
              final user = event.session?.user;
              if (user != null) {
                state = (state as Authenticated).withUser(userProfile(user));
              }
            }
          },
          onError: (Object error, StackTrace stack) {
            // A refresh network failure must not discard offline data.
          },
        );
    ref.listen(syncControllerProvider, (_, next) {
      if (next is SyncSuccess) unawaited(_reconcile());
    });
    final realtime = ref.read(realtimeChannelProvider);
    ref.onDispose(() {
      _disposed = true;
      _timer?.cancel();
      subscription.cancel();
      realtime.stop();
    });
    unawaited(Future<void>.microtask(_restore));
    return const AuthLoading();
  }

  Future<void> _restore() async {
    final user = ref.read(supabaseProvider).auth.currentUser;
    if (user == null) {
      state = const Unauthenticated();
      return;
    }
    try {
      await _promoteSession(LoginResult(user: userProfile(user)));
    } catch (_) {
      if (!_disposed) state = const Unauthenticated();
    }
  }

  Future<void> login(String email, String password) async => _promoteSession(
    await ref.read(authRepositoryProvider).login(email, password),
  );

  /// False means email confirmation is required before signing in.
  Future<bool> register({
    required String email,
    required String password,
  }) async {
    final result = await ref
        .read(authRepositoryProvider)
        .register(email: email, password: password);
    if (result == null) return false;
    await _promoteSession(result);
    return true;
  }

  Future<void> completePairing(LoginResult result) => _promoteSession(result);

  Future<void> _promoteSession(LoginResult result) async {
    final generation = ++_generation;
    final cache = ref.read(userCacheProvider);
    final previous = await cache.read();
    if (previous != null && previous.id != result.user.id) {
      await ref.read(databaseProvider).wipeAll();
    }
    await cache.save(result.user);
    if (_disposed || generation != _generation) return;
    final cachedSource = previous?.id == result.user.id
        ? await ref.read(databaseProvider).watchActiveSource().first
        : null;
    if (_disposed || generation != _generation) return;
    final hasCachedCatalog = cachedSource?.lastSyncAt != null;
    state = Authenticated(result.user, sourceRestoring: !hasCachedCatalog);
    ref.read(databaseProvider).syncSink = ref.read(syncRepositoryProvider);
    _timer?.cancel();
    ref.read(realtimeChannelProvider).stop();
    if (hasCachedCatalog) {
      unawaited(_finishSourceRestore(generation));
    } else {
      await _finishSourceRestore(generation);
    }
  }

  Future<void> _finishSourceRestore(int generation) async {
    var failed = false;
    try {
      await _refreshSource(awaitCatalog: true);
    } catch (_) {
      failed = true;
    }
    if (_disposed || generation != _generation) return;
    final user = (state as Authenticated).user;
    state = Authenticated(user, sourceRestoreFailed: failed);
    ref.read(realtimeChannelProvider).start(_onRealtimeEvent);
    _timer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => unawaited(_refreshSource()),
    );
  }

  Future<void> retrySourceRestore() async {
    final current = state;
    if (current is Authenticated && !current.sourceRestoring) {
      await _promoteSession(LoginResult(user: current.user));
    }
  }

  void _onRealtimeEvent(String type, Map<String, dynamic> data) {
    if (state is! Authenticated) return;
    switch (type) {
      case 'provision':
        unawaited(_refreshSource());
      case 'sync':
        unawaited(_reconcile());
      case 'remote':
        final command = RemoteCommand.parse(data);
        if (command != null) ref.read(remoteCommandsProvider).emit(command);
      case 'remote-status':
        ref.read(remoteStatusProvider.notifier).onEvent(data);
    }
  }

  Future<void> _refreshSource({bool awaitCatalog = false}) async {
    if (_refreshing) {
      if (awaitCatalog) {
        await _refreshDone!.future;
        if (_disposed || state is! Authenticated) return;
        return _refreshSource(awaitCatalog: true);
      }
      _refreshAgain = true;
      return;
    }
    _refreshing = true;
    _refreshDone = Completer<void>();
    final generation = _generation;
    try {
      final repository = ref.read(provisionRepositoryProvider);
      final payload = await repository.fetch().timeout(
        const Duration(seconds: 20),
      );
      if (_disposed || generation != _generation || state is! Authenticated) {
        return;
      }

      final db = ref.read(databaseProvider);
      final existing = await db.watchActiveSource().first;
      if (_disposed || generation != _generation || state is! Authenticated) {
        return;
      }

      if (payload == null) {
        if (existing != null) await db.deleteSource(existing.id);
      } else {
        final replacing =
            existing == null || !payload.matchesPlaylist(existing);
        final needsCatalog = replacing || existing.lastSyncAt == null;
        if (needsCatalog) {
          state = Authenticated(
            (state as Authenticated).user,
            sourceRestoring: true,
          );
        }
        final changed = await repository.applyProvisionedSource(payload);
        if (_disposed || generation != _generation) return;
        if (changed || needsCatalog || awaitCatalog) {
          final source = await db.watchActiveSource().first;
          if (_disposed || generation != _generation) return;
          if (source != null) {
            final synced = await ref
                .read(syncControllerProvider.notifier)
                .syncSource(source, waitForGuide: false);
            if (!synced && source.lastSyncAt == null) {
              throw StateError('Initial catalog sync failed');
            }
          }
        }
      }
      if (_disposed || generation != _generation || state is! Authenticated) {
        return;
      }
      final current = state as Authenticated;
      if (current.sourceRestoreFailed || current.sourceRestoring) {
        state = Authenticated(current.user);
      }
      unawaited(_reconcile());
    } catch (_) {
      // Keep offline accounts usable, but do not mistake a failed fetch for no source.
      if (!_disposed && generation == _generation && state is Authenticated) {
        final cached = await ref
            .read(databaseProvider)
            .watchActiveSource()
            .first;
        if (_disposed || generation != _generation) return;
        if (cached?.lastSyncAt == null) {
          if (awaitCatalog) rethrow;
          state = Authenticated(
            (state as Authenticated).user,
            sourceRestoreFailed: true,
          );
        }
      }
    } finally {
      _refreshing = false;
      _refreshDone!.complete();
      if (_refreshAgain && !_disposed && state is Authenticated) {
        _refreshAgain = false;
        unawaited(_refreshSource());
      }
    }
  }

  Future<void> _reconcile() async {
    if (state is! Authenticated || _disposed) return;
    if (_reconciling) {
      _reconcileAgain = true;
      return;
    }
    _reconciling = true;
    try {
      final source = await ref.read(databaseProvider).watchActiveSource().first;
      if (source != null) {
        await ref.read(syncRepositoryProvider).reconcile(source.id);
      }
    } catch (_) {
      /* Local writes remain queued in SQLite for retry. */
    } finally {
      _reconciling = false;
      if (_reconcileAgain && !_disposed && state is Authenticated) {
        _reconcileAgain = false;
        unawaited(_reconcile());
      }
    }
  }

  Future<void> updateProfile({
    required String? firstName,
    required String? lastName,
    required String? phone,
  }) async {
    final user = await ref
        .read(authRepositoryProvider)
        .updateProfile(firstName: firstName, lastName: lastName, phone: phone);
    await ref.read(userCacheProvider).save(user);
    final current = state;
    if (current is Authenticated) state = current.withUser(user);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => ref
      .read(authRepositoryProvider)
      .changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

  Future<void> _clearSession() async {
    ++_generation;
    _timer?.cancel();
    ref.read(realtimeChannelProvider).stop();
    ref.read(databaseProvider).syncSink = null;
    ref.read(remoteStatusProvider.notifier).clear();
    await ref.read(databaseProvider).wipeAll();
    await ref.read(userCacheProvider).clear();
    if (!_disposed) state = const Unauthenticated();
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    // The auth event owns clearing the local session.
  }
}
