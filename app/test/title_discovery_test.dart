import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/discovery/discovery_repository.dart';
import 'package:zauxoflix/data/discovery/title_identity.dart';
import 'package:zauxoflix/data/discovery/trakt_client.dart';
import 'package:zauxoflix/data/xtream/xtream_models.dart';

class FixtureClient implements DiscoveryClient {
  int lookups = 0;
  bool offline = false;
  static const uk = TraktTitle(1, 'The Office', 2001, 'tt0290978', null);
  static const us = TraktTitle(2, 'The Office', 2005, 'tt0386676', null);
  static const related = TraktTitle(3, 'Severance', 2022, 'tt11280740', 95396);
  @override
  Future<List<TraktTitle>> lookup(
    CatalogKind kind,
    String name,
    String? external,
  ) async {
    lookups++;
    if (offline) throw StateError('offline');
    return [uk, us, related];
  }

  @override
  Future<TitleDiscovery> details(CatalogKind kind, TraktTitle title) async {
    if (offline) throw StateError('offline');
    return TitleDiscovery(
      title,
      8,
      {'en': 'xEQP4VVuyrY'},
      [title, uk, us, related],
    );
  }
}

void main() {
  late AppDatabase db;
  late int source;
  late FixtureClient client;
  late DiscoveryRepository repo;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    source = await db.insertSource(
      SourcesCompanion.insert(
        name: 'Preview',
        serverUrl: '',
        username: '',
        password: '',
      ),
    );
    client = FixtureClient();
    repo = DiscoveryRepository(db, client);
  });
  tearDown(() => db.close());
  CatalogTitle key(int id, String name, {String? external, int? year}) => (
    source: source,
    kind: CatalogKind.series,
    id: id,
    name: name,
    year: year,
    external: external,
  );
  test(
    'remakes require a unique match, year or external ID; cache is isolated when an ID is reused',
    () async {
      expect(await repo.load(key(1, 'The Office')), isNull);
      final uk = key(1, 'The Office (2001) HD');
      final pair = await Future.wait([repo.load(uk), repo.load(uk)]);
      expect(pair.map((d) => d?.title.imdb), ['tt0290978', 'tt0290978']);
      expect(client.lookups, 2);
      expect(
        (await repo.load(key(2, 'مكتب', external: 'tt0386676')))?.title.id,
        2,
      );
      client.offline = true;
      expect((await DiscoveryRepository(db, client).load(uk))?.title.id, 1);
      expect(await repo.load(key(1, 'Different title')), isNull);
      expect(await DiscoveryRepository(db, null).load(uk), isNull);
    },
  );
  test(
    'related titles include unseen local titles and exclude remakes, other playlists and the seed',
    () async {
      final other = await db.insertSource(
        SourcesCompanion.insert(
          name: 'Other',
          serverUrl: '',
          username: '',
          password: '',
        ),
      );
      await db.replaceSeries(source, [
        SeriesItemsCompanion.insert(
          sourceId: source,
          seriesId: 10,
          name: 'The Office (2001)',
        ),
        SeriesItemsCompanion.insert(
          sourceId: source,
          seriesId: 11,
          name: 'The Office',
        ),
        SeriesItemsCompanion.insert(
          sourceId: source,
          seriesId: 12,
          name: 'سيفرنس',
          externalId: const Value('tmdb:95396'),
        ),
      ]);
      await db.replaceSeries(other, [
        SeriesItemsCompanion.insert(
          sourceId: other,
          seriesId: 30,
          name: 'The Office (2005)',
        ),
      ]);
      final seed = key(10, 'The Office (2001)');
      final items = await repo.playable(seed, (await repo.load(seed))!);
      expect(items.map((i) => i.id), [12]);
      expect(items.single.title, 'سيفرنس');
    },
  );
  test(
    'yearless recommendations retain verified identity offline and fetch details on open',
    () async {
      await db.replaceSeries(source, [
        SeriesItemsCompanion.insert(
          sourceId: source,
          seriesId: 12,
          name: 'Severance',
        ),
      ]);
      final seed = key(10, 'The Office (2001)');
      final details = (await repo.load(seed))!;
      expect((await repo.playable(seed, details)).single.id, 12);
      final lookupCount = client.lookups;
      client.offline = true;
      final reopened = DiscoveryRepository(db, client);
      expect((await reopened.playable(seed, details)).single.id, 12);
      expect(client.lookups, lookupCount);
      client.offline = false;
      expect((await reopened.load(key(12, 'Severance')))?.rating, 8);
    },
  );
  test(
    'both people endpoints match headshots by person ID and retain missing photos',
    () async {
      final api = TraktClient('fixture');
      addTearDown(api.dio.close);
      final paths = <String>[];
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            paths.add(request.path);
            expect(request.queryParameters['extended'], 'full');
            handler.resolve(
              Response<Object?>(
                requestOptions: request,
                statusCode: 200,
                data: {
                  'cast': [
                    for (final (id, url) in [
                      (
                        'nm0000001',
                        'media.trakt.tv/people/1/medium/headshot.webp',
                      ),
                      ('nm0000002', 'https://trakt.tv.example.com/fake.webp'),
                      ('wrong', 'media.trakt.tv/people/3/medium/headshot.webp'),
                    ])
                      {
                        'characters': ['Role'],
                        'person': {
                          'ids': {'imdb': id},
                          'name': 'Same name',
                          'images': {
                            'headshot': [url],
                          },
                        },
                      },
                  ],
                },
              ),
            );
          },
        ),
      );
      for (final kind in [CatalogKind.vod, CatalogKind.series]) {
        final cast = await api.cast(kind, 'tt0000022');
        expect(cast.map((p) => p.id), ['nm0000001', 'nm0000002']);
        expect(
          cast.first.photo,
          'https://media.trakt.tv/people/1/medium/headshot.webp',
        );
        expect(cast.last.photo, isNull);
        expect(cast.first.roles, ['Role']);
      }
      expect(paths, ['/movies/tt0000022/people', '/shows/tt0000022/people']);
    },
  );
  test(
    'provider scale, trailer languages, validated links, bilingual normalization',
    () {
      final vod = XtreamVodStream.fromJson({
        'stream_id': 1,
        'rating_5based': '4.1',
        'rating': '8.2',
        'imdb_id': 'tt0386676',
      })!;
      expect(providerRating(vod.rating, vod.ratingScale), 'Provider 4.1/5');
      expect(providerRating(7.2, null), 'Provider 7.2');
      expect(vod.externalId, 'tt0386676');
      expect(
        discoveryName('AR | بَاب الحارة (2006) HD'),
        discoveryName('باب الحارة'),
      );
      expect(
        youtubeId('https://www.youtube.com/watch?v=xEQP4VVuyrY'),
        'xEQP4VVuyrY',
      );
      expect(
        youtubeId('https://youtube.com.example.com/watch?v=xEQP4VVuyrY'),
        isNull,
      );
      final data = TitleDiscovery(FixtureClient.related, 8, {
        'ar': 'a',
        'en': 'e',
      }, []);
      expect(data.trailer('ar'), 'a');
      expect(data.trailer('fr'), 'e');
    },
  );
  test(
    '429 honors Retry-After and a later repository load can retry',
    () async {
      final http = TraktClient('fixture-client');
      var requests = 0;
      http.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests++;
            expect(request.uri.host, 'api.trakt.tv');
            expect(request.queryParameters['query'], 'Severance');
            handler.reject(
              DioException(
                requestOptions: request,
                response: Response<Object?>(
                  requestOptions: request,
                  statusCode: 429,
                  headers: Headers.fromMap({
                    'retry-after': ['120'],
                  }),
                ),
              ),
            );
          },
        ),
      );
      final repository = DiscoveryRepository(db, http);
      expect(await repository.load(key(10, 'Severance')), isNull);
      expect(await repository.load(key(10, 'Severance')), isNull);
      expect(requests, 1);
      expect(await db.select(db.discoveryEntries).get(), isEmpty);
      http.dio.close();
    },
  );
  test(
    'a video service error still returns the rating and related shows',
    () async {
      final api = TraktClient('fixture-client');
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            if (request.path.endsWith('/videos')) {
              handler.reject(
                DioException(
                  requestOptions: request,
                  response: Response<Object?>(
                    requestOptions: request,
                    statusCode: 503,
                  ),
                ),
              );
            } else {
              handler.resolve(
                Response<Object?>(
                  requestOptions: request,
                  statusCode: 200,
                  data: request.path.endsWith('/ratings')
                      ? {'rating': 8.3, 'votes': 23}
                      : [FixtureClient.related.toJson()],
                ),
              );
            }
          },
        ),
      );
      final result = await api.details(CatalogKind.series, FixtureClient.uk);
      expect(result.rating, 8.3);
      expect(result.related.single.id, FixtureClient.related.id);
      expect(result.trailer('en'), isNull);
      expect(result.complete, isFalse);
      api.dio.close();
    },
  );
}
