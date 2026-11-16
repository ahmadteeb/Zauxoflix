import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zauxoflix/data/backend/backend_providers.dart';
import 'package:zauxoflix/data/backend/device_identity.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:zauxoflix/data/backend/auth_repository.dart';
import 'package:zauxoflix/data/backend/key_value_store.dart';
import 'package:zauxoflix/data/backend/secure_session_storage.dart';

class MemoryStore implements KeyValueStore {
  final data = <String, String>{};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }
}

void main() {
  final user = <String, dynamic>{
    'id': 'user-1',
    'email': 'viewer@example.com',
    'aud': 'authenticated',
    'app_metadata': <String, dynamic>{},
    'user_metadata': {'firstName': 'Viewer'},
    'created_at': '2026-01-01T00:00:00Z',
  };
  test('signup with email confirmation does not invent a session', () async {
    final client = sb.SupabaseClient(
      'https://test.supabase.co',
      'key',
      authOptions: const sb.AuthClientOptions(
        authFlowType: sb.AuthFlowType.implicit,
      ),
      httpClient: MockClient((request) async {
        expect(request.url.path, '/auth/v1/signup');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'viewer@example.com');
        expect(body['password'], 'password123');
        expect(body.containsKey('activationCode'), isFalse);
        return http.Response(jsonEncode(user), 200, request: request);
      }),
    );
    addTearDown(client.dispose);
    expect(
      await AuthRepository(
        client,
      ).register(email: 'viewer@example.com', password: 'password123'),
      isNull,
    );
    expect(client.auth.currentSession, isNull);
  });
  test(
    'login delegates session ownership to Supabase and maps the profile',
    () async {
      final client = sb.SupabaseClient(
        'https://test.supabase.co',
        'key',
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'access_token': 'access',
              'refresh_token': 'refresh',
              'expires_in': 3600,
              'token_type': 'bearer',
              'user': user,
            }),
            200,
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      final result = await AuthRepository(
        client,
      ).login('viewer@example.com', 'password123');
      expect(result.user.firstName, 'Viewer');
      expect(client.auth.currentSession!.refreshToken, 'refresh');
    },
  );
  test('auth rejection preserves a useful error for the form', () async {
    final client = sb.SupabaseClient(
      'https://test.supabase.co',
      'key',
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'error_code': 'invalid_credentials',
            'msg': 'Invalid login credentials',
          }),
          400,
          request: request,
        ),
      ),
    );
    addTearDown(client.dispose);
    await expectLater(
      AuthRepository(client).login('viewer@example.com', 'wrong'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.code,
          'code',
          'invalid_credentials',
        ),
      ),
    );
  });
  test('a cold start without a session leaves the splash screen', () async {
    final client = sb.SupabaseClient('https://test.supabase.co', 'key');
    final container = ProviderContainer(
      overrides: [
        supabaseProvider.overrideWithValue(client),
        deviceIdentityProvider.overrideWithValue(
          const DeviceIdentity(deviceId: 'test-device', platform: 'linux'),
        ),
      ],
    );
    addTearDown(client.dispose);
    addTearDown(container.dispose);
    expect(container.read(authControllerProvider), isA<AuthLoading>());
    await Future<void>.delayed(Duration.zero);
    expect(container.read(authControllerProvider), isA<Unauthenticated>());
  });
  test('secure sessions are isolated by project and removable', () async {
    final store = MemoryStore();
    final first = SecureSessionStorage(store, 'https://first.supabase.co');
    final second = SecureSessionStorage(store, 'https://second.supabase.co');
    await first.persistSession('private-session');
    expect(await first.hasAccessToken(), isTrue);
    expect(await second.accessToken(), isNull);
    await first.removePersistedSession();
    expect(await first.hasAccessToken(), isFalse);
  });
}
