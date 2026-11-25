import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/data/backend/provision_models.dart';
import 'package:zauxoflix/data/backend/provision_repository.dart';
import 'package:zauxoflix/data/db/app_database.dart';

ProvisionRepository _repoWith(AppDatabase db, Map<String, dynamic> body) {
  final client = SupabaseClient(
    'https://test.supabase.co',
    'key',
    httpClient: MockClient((request) async {
      expect(request.url.path, '/rest/v1/rpc/read_source');
      return http.Response(
        jsonEncode(body['source']),
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    }),
  );
  client.auth.recoverSession(
    jsonEncode({
      'access_token': 'token',
      'refresh_token': 'refresh',
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': {
        'id': 'user-1',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
        'aud': 'authenticated',
        'created_at': '2026-01-01T00:00:00Z',
      },
    }),
  );
  addTearDown(client.dispose);
  return ProvisionRepository(client, db);
}

void main() {
  group('SourcePayload.fromJson', () {
    test('maps an xtream source', () {
      final payload = SourcePayload.fromJson({
        'type': 'xtream',
        'serverUrl': 'http://p.tv:8080',
        'username': 'u',
        'password': 'p',
      });
      expect(payload.type, SourceType.xtream);
      expect(payload.serverUrl, 'http://p.tv:8080');
      expect(payload.username, 'u');
      expect(payload.epgUrl, isNull);
    });

    test('maps an m3u source into serverUrl + epgUrl', () {
      final payload = SourcePayload.fromJson({
        'type': 'm3u',
        'm3uUrl': 'http://p.tv/list.m3u',
        'epgUrl': 'http://p.tv/epg.xml',
      });
      expect(payload.type, SourceType.m3u);
      expect(payload.serverUrl, 'http://p.tv/list.m3u');
      expect(payload.username, '');
      expect(payload.password, '');
      expect(payload.epgUrl, 'http://p.tv/epg.xml');
    });
  });

  group('applyProvisionedSource', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    Map<String, dynamic> xtreamBody(String password) => {
      'user': {'id': 'u1', 'email': 'v@x.com', 'role': 'USER'},
      'source': {
        'type': 'xtream',
        'serverUrl': 'http://p.tv',
        'username': 'u',
        'password': password,
      },
    };

    test('inserts a row when none exists', () async {
      final repo = _repoWith(db, xtreamBody('p'));
      final result = await repo.fetch();

      final changed = await repo.applyProvisionedSource(result!);

      expect(changed, isTrue);
      final source = await db.watchActiveSource().first;
      expect(source!.serverUrl, 'http://p.tv');
      expect(source.sourceType, SourceType.xtream);
    });

    test('is a no-op when the stored source already matches', () async {
      await db.insertSource(
        SourcesCompanion(
          name: const Value('p.tv'),
          sourceType: const Value(SourceType.xtream),
          serverUrl: const Value('http://p.tv'),
          username: const Value('u'),
          password: const Value('p'),
        ),
      );
      final repo = _repoWith(db, xtreamBody('p'));
      final result = await repo.fetch();

      final changed = await repo.applyProvisionedSource(result!);

      expect(changed, isFalse);
    });

    test(
      'removing a legacy discovered guide or changing the override preserves the source',
      () async {
        const payload = SourcePayload(
          type: SourceType.m3u,
          serverUrl: 'http://local/list',
          username: '',
          password: '',
        );
        final repo = _repoWith(db, {});
        final original = await repo.adoptSource(payload);
        await db.addFavorite(
          sourceId: original.id,
          kind: CatalogKind.live,
          itemId: 1,
          name: 'News',
        );
        await (db.update(
          db.sources,
        )..where((s) => s.id.equals(original.id))).write(
          const SourcesCompanion(epgUrl: Value('http://local/legacy-guide')),
        );
        expect(await repo.adoptSource(payload), (
          id: original.id,
          changed: true,
        ));
        expect(await repo.adoptSource(payload), (
          id: original.id,
          changed: false,
        ));
        expect(
          (await db.watchFavorites(original.id).first).single.name,
          'News',
        );
      },
    );

    test('replaces the row when credentials change', () async {
      await db.insertSource(
        SourcesCompanion(
          name: const Value('p.tv'),
          sourceType: const Value(SourceType.xtream),
          serverUrl: const Value('http://p.tv'),
          username: const Value('u'),
          password: const Value('old'),
        ),
      );
      final repo = _repoWith(db, xtreamBody('new'));
      final result = await repo.fetch();

      final changed = await repo.applyProvisionedSource(result!);

      expect(changed, isTrue);
      final source = await db.watchActiveSource().first;
      expect(source!.password, 'new');
    });
  });
}
