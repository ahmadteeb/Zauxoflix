import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/data/backend/sync_repository.dart';
import 'package:zauxoflix/data/db/app_database.dart';

typedef _Request = ({String method, String path, Object? data});

class _RecordingAdapter {
  _RecordingAdapter({this.favorites = const [], this.progress = const []});
  final List<Map<String, dynamic>> favorites;
  final List<Map<String, dynamic>> progress;
  final List<_Request> requests = [];
  Iterable<_Request> to(String path) => requests.where(
    (r) =>
        r.path == path &&
        !r.path.endsWith('read_favorites') &&
        !r.path.endsWith('read_progress'),
  );
  late final http.Client httpClient = MockClient((request) async {
    requests.add((
      method: request.method,
      path: request.url.path,
      data: request.body.isEmpty ? null : jsonDecode(request.body),
    ));
    List<Map<String, dynamic>>? data;
    if (request.url.path.endsWith('read_favorites') ||
        request.url.path.endsWith('read_progress')) {
      final all = request.url.path.endsWith('read_favorites')
          ? favorites
          : progress;
      final params = jsonDecode(request.body) as Map<String, dynamic>;
      final offset = params['page_offset'] as int;
      final limit = params['page_size'] as int;
      data = all.skip(offset).take(limit).toList();
    }
    return http.Response(
      jsonEncode(data),
      200,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  });
}

SyncRepository _repoWith(AppDatabase db, _RecordingAdapter adapter) {
  final client = SupabaseClient(
    'https://test.supabase.co',
    'test-key',
    httpClient: adapter.httpClient,
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
  return SyncRepository(client, db);
}

void main() {
  late AppDatabase db;
  const sourceId = 1;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.insertSource(
      SourcesCompanion.insert(
        name: 'test',
        serverUrl: 'http://127.0.0.1:1',
        username: 'u',
        password: 'p',
      ),
    );
  });
  tearDown(() => db.close());

  group('pushes', () {
    test('pushProgress for an episode targets the SERIES key', () async {
      final adapter = _RecordingAdapter();
      final repo = _repoWith(db, adapter);

      await repo.pushProgress(WatchKind.episode, 500, 7, 120, 1400);

      final put = adapter.to('/rest/v1/rpc/sync_progress').single;
      expect(put.method, 'POST');
      final body = put.data as Map<String, dynamic>;
      expect(body['item_type'], 'SERIES');
      expect(body['item_id'], '7');
      expect(body['episode_id'], '500');
      expect(body['position_sec'], 120);
    });

    test('pushFavorite targets the MOVIE key', () async {
      final adapter = _RecordingAdapter();
      final repo = _repoWith(db, adapter);

      await repo.pushFavorite(CatalogKind.vod, 10);

      final post = adapter.to('/rest/v1/rpc/sync_favorite').single;
      expect(post.method, 'POST');
      final body = post.data as Map<String, dynamic>;
      expect(body['item_type'], 'MOVIE');
      expect(body['item_id'], '10');
    });
  });

  test('reconcile fetches favorites beyond the first Supabase page', () async {
    await db.replaceMovies(sourceId, [
      MoviesCompanion.insert(
        sourceId: sourceId,
        streamId: 500,
        name: 'Last movie',
      ),
    ]);
    final adapter = _RecordingAdapter(
      favorites: [
        for (var i = 0; i <= 500; i++)
          {
            'itemType': 'MOVIE',
            'itemId': '$i',
            'createdAt': '2026-07-01T00:00:00Z',
          },
      ],
    );
    await _repoWith(db, adapter).reconcile(sourceId);
    expect((await db.allFavorites(sourceId)).single.itemId, 500);
  });

  group('reconcile favorites', () {
    test('pulls a remote favorite whose item is in the catalog', () async {
      await db.replaceMovies(sourceId, [
        MoviesCompanion.insert(
          sourceId: sourceId,
          streamId: 10,
          name: 'Movie A',
        ),
      ]);
      final adapter = _RecordingAdapter(
        favorites: [
          {
            'itemType': 'MOVIE',
            'itemId': '10',
            'createdAt': '2026-07-01T00:00:00.000Z',
          },
        ],
      );
      final repo = _repoWith(db, adapter);

      await repo.reconcile(sourceId);

      final local = await db.allFavorites(sourceId);
      expect(local.map((f) => f.itemId), contains(10));
      expect(local.single.kind, CatalogKind.vod);
      expect(local.single.name, 'Movie A');
    });

    test('skips a remote favorite missing from the local catalog', () async {
      final adapter = _RecordingAdapter(
        favorites: [
          {
            'itemType': 'MOVIE',
            'itemId': '999',
            'createdAt': '2026-07-01T00:00:00.000Z',
          },
        ],
      );
      final repo = _repoWith(db, adapter);

      await repo.reconcile(sourceId);

      expect(await db.allFavorites(sourceId), isEmpty);
    });

    test('pushes a local-only favorite to the server', () async {
      await db.replaceSeries(sourceId, [
        SeriesItemsCompanion.insert(
          sourceId: sourceId,
          seriesId: 20,
          name: 'Show',
        ),
      ]);
      await db.addFavorite(
        sourceId: sourceId,
        kind: CatalogKind.series,
        itemId: 20,
        name: 'Show',
      );
      final adapter = _RecordingAdapter();
      final repo = _repoWith(db, adapter);

      await repo.reconcile(sourceId);

      final post = adapter.to('/rest/v1/rpc/sync_favorite').single;
      expect(post.method, 'POST');
      final body = post.data as Map<String, dynamic>;
      expect(body['item_type'], 'SERIES');
      expect(body['item_id'], '20');
    });
  });

  group('reconcile progress', () {
    test('pulls newer remote progress into the local store', () async {
      await db.replaceMovies(sourceId, [
        MoviesCompanion.insert(
          sourceId: sourceId,
          streamId: 10,
          name: 'Movie A',
        ),
      ]);
      final adapter = _RecordingAdapter(
        progress: [
          {
            'itemType': 'MOVIE',
            'itemId': '10',
            'episodeId': '',
            'positionSec': 90,
            'durationSec': 300,
            'updatedAt': '2026-07-18T10:00:00.000Z',
          },
        ],
      );
      final repo = _repoWith(db, adapter);

      await repo.reconcile(sourceId);

      final row = await db.watchPosition(sourceId, WatchKind.movie, 10).first;
      expect(row, isNotNull);
      expect(row!.positionSecs, 90);
      expect(row.title, 'Movie A');
    });

    test('keeps a newer local position and pushes it upstream', () async {
      await db.replaceMovies(sourceId, [
        MoviesCompanion.insert(
          sourceId: sourceId,
          streamId: 10,
          name: 'Movie A',
        ),
      ]);
      // Local row is newer than the remote copy below.
      await db.savePosition(
        PlaybackPositionsCompanion.insert(
          sourceId: sourceId,
          kind: WatchKind.movie,
          itemId: 10,
          title: 'Movie A',
          positionSecs: 200,
          durationSecs: 300,
          updatedAt: DateTime.utc(2026, 7, 18, 12),
        ),
      );
      final adapter = _RecordingAdapter(
        progress: [
          {
            'itemType': 'MOVIE',
            'itemId': '10',
            'episodeId': '',
            'positionSec': 90,
            'durationSec': 300,
            'updatedAt': '2026-07-18T10:00:00.000Z',
          },
        ],
      );
      final repo = _repoWith(db, adapter);

      await repo.reconcile(sourceId);

      // Local position is untouched (newer wins)...
      final row = await db.watchPosition(sourceId, WatchKind.movie, 10).first;
      expect(row!.positionSecs, 200);
      // ...and the local copy is pushed back to the server.
      final put = adapter.to('/rest/v1/rpc/sync_progress').single;
      expect(put.method, 'POST');
      expect((put.data as Map<String, dynamic>)['position_sec'], 200);
    });
  });
}
