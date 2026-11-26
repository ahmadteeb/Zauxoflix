import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/sync/catalog_sync_service.dart';
import 'package:zauxoflix/data/xtream/xtream_api.dart';

/// Canned Xtream responses with the type sloppiness seen on real panels:
/// ids as strings and ints, ratings as string/num, epoch dates as strings.
const _responses = <String, Object>{
  '': {
    'user_info': {
      'auth': 1,
      'status': 'Active',
      'exp_date': '1790000000',
      'max_connections': '2',
    },
    'server_info': {'url': 'localhost'},
  },
  'get_live_categories': [
    {'category_id': '1', 'category_name': 'News', 'parent_id': 0},
    {'category_id': 2, 'category_name': 'Sports'},
  ],
  'get_vod_categories': [
    {'category_id': '10', 'category_name': 'Action'},
  ],
  'get_series_categories': [
    {'category_id': '20', 'category_name': 'Drama'},
  ],
  'get_live_streams': [
    {
      'num': 1,
      'name': 'News 24',
      'stream_id': 101,
      'stream_icon': 'http://icons/news24.png',
      'epg_channel_id': 'news24.example',
      'category_id': '1',
    },
    {
      'num': '2',
      'name': 'Sports HD',
      'stream_id': '102',
      'stream_icon': '',
      'category_id': 2,
    },
    {'name': 'broken entry without id'},
  ],
  'get_vod_streams': [
    {
      'stream_id': '201',
      'name': 'Midnight Horizon',
      'stream_icon': 'http://icons/mh.jpg',
      'category_id': '10',
      'container_extension': 'mkv',
      'rating': '7.4',
      'rating_5based': 3.7,
      'added': '1750000000',
    },
  ],
  'get_series': [
    {
      'series_id': 301,
      'name': 'Broken Compass',
      'cover': 'http://icons/bc.jpg',
      'category_id': '20',
      'plot': 'A crew loses its way.',
      'rating': 8,
      'last_modified': 1751000000,
    },
  ],
};

/// flutter_test stubs out HttpClient (every request returns 400); restore the
/// real one so tests can talk to the local fake server.
class _RealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttpOverrides();

  late HttpServer server;
  late AppDatabase db;
  late Map<String, Object> responses;
  late String xml;
  late Map<String, String> tags;
  late Map<String, String?> conditionalRequests;

  String? playlist;
  Completer<void>? guideRequested, allowGuide;
  const goodGuide =
      '<tv><programme start="20200101000000" stop="20990101000000" channel="news24.example"><title>Last good guide</title></programme></tv>';

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    responses = Map.of(_responses);
    xml = goodGuide;
    tags = {};
    conditionalRequests = {};
    playlist = null;
    guideRequested = allowGuide = null;
    server.listen((request) async {
      if (request.uri.path == '/xmltv.php') {
        guideRequested?.complete();
        await allowGuide?.future;
        request.response.write(xml);
        await request.response.close();
        return;
      }
      final action = request.uri.queryParameters['action'] ?? request.uri.path;
      final tag = tags[action];
      if (tag != null) {
        final sent = request.headers.value('if-none-match');
        conditionalRequests[action] = sent;
        request.response.headers.set('etag', tag);
        if (sent == tag) {
          request.response.statusCode = HttpStatus.notModified;
          await request.response.close();
          return;
        }
      }
      if (request.uri.path == '/list.m3u') {
        request.response.write(playlist);
        await request.response.close();
        return;
      }
      request.response
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode(
            responses[action == '/player_api.php' ? '' : action] ?? [],
          ),
        );
      await request.response.close();
    });
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    await server.close(force: true);
  });

  test('authenticate parses messy user_info', () async {
    final api = XtreamApi(
      XtreamCredentials(
        serverUrl: '127.0.0.1:${server.port}',
        username: 'u',
        password: 'p',
      ),
    );
    final info = await api.authenticate();
    expect(info.authenticated, isTrue);
    expect(info.status, 'Active');
    expect(info.maxConnections, 2);
    expect(info.expiresAt, isNotNull);
  });

  test('syncAll populates catalog with tolerant parsing', () async {
    final id = await db.insertSource(
      const SourcesCompanion(
        name: Value('test'),
        serverUrl: Value(''), // overwritten below via real port
        username: Value('u'),
        password: Value('p'),
      ),
    );
    await (db.update(db.sources)..where((s) => s.id.equals(id))).write(
      SourcesCompanion(serverUrl: Value('http://127.0.0.1:${server.port}')),
    );
    final source = await (db.select(
      db.sources,
    )..where((s) => s.id.equals(id))).getSingle();

    final stages = <String>[];
    await CatalogSyncService(db).syncAll(source, onStage: stages.add);

    expect(stages, isNotEmpty);

    final counts = await db.catalogCounts(id);
    expect(counts.live, 2, reason: 'entry without stream_id is skipped');
    expect(counts.movies, 1);
    expect(counts.series, 1);

    final liveCategories = await db.watchCategories(id, CatalogKind.live).first;
    expect(liveCategories.map((c) => c.name), ['News', 'Sports']);

    final channels = await db.watchLiveChannels(id).first;
    expect(channels.first.name, 'News 24');
    expect(channels.first.channelNumber, 1);
    // String stream_id "102" and num "2" coerced to ints:
    expect(channels.last.streamId, 102);
    expect(channels.last.channelNumber, 2);

    final movies = await db.watchMovies(id).first;
    final movie = movies.single;
    expect(movie.streamId, 201);
    expect(movie.containerExtension, 'mkv');
    expect(movie.rating, 3.7, reason: 'prefers rating_5based');
    expect(movie.addedAt, isNotNull);

    final series = (await db.watchSeries(id).first).single;
    expect(series.seriesId, 301);
    expect(series.rating, 8.0);

    final synced = await (db.select(
      db.sources,
    )..where((s) => s.id.equals(id))).getSingle();
    expect(synced.lastSyncAt, isNotNull);

    // Category filter narrows results.
    final newsOnly = await db.watchLiveChannels(id, categoryId: '1').first;
    expect(newsOnly.single.streamId, 101);

    // Re-sync replaces rather than duplicates.
    await CatalogSyncService(db).syncAll(source);
    final counts2 = await db.catalogCounts(id);
    expect(counts2.live, 2);

    // Removing the source clears everything.
    await db.deleteSource(id);
    final counts3 = await db.catalogCounts(id);
    expect((counts3.live, counts3.movies, counts3.series), (0, 0, 0));
  });

  Future<Source> addTestSource() async {
    await db.insertSource(
      SourcesCompanion.insert(
        name: 'test',
        serverUrl: 'http://127.0.0.1:${server.port}',
        username: 'u',
        password: 'p',
      ),
    );
    return (await db.watchActiveSource().first)!;
  }

  test(
    'late provider error preserves all sections and valid empty arrays can replace them',
    () async {
      final source = await addTestSource();
      final sync = CatalogSyncService(db);
      await sync.syncAll(source);
      final timestamp = (await db.watchActiveSource().first)!.lastSyncAt;
      responses['get_vod_streams'] = [];
      responses['get_series'] = {'error': 'temporary outage'};
      await expectLater(sync.syncAll(source), throwsFormatException);
      expect((await db.watchMovies(source.id).first).single.streamId, 201);
      expect((await db.watchSeries(source.id).first).single.seriesId, 301);
      expect((await db.watchActiveSource().first)!.lastSyncAt, timestamp);
      responses['get_series'] = [
        {'error': 'invalid listing'},
      ];
      await expectLater(sync.syncAll(source), throwsFormatException);
      expect((await db.watchMovies(source.id).first).single.streamId, 201);
      responses['get_series'] = [];
      await sync.syncAll(source);
      expect(await db.watchMovies(source.id).first, isEmpty);
      expect(await db.watchSeries(source.id).first, isEmpty);
    },
  );

  test(
    'catalog is readable while guide loads and a truncated guide rolls back even after a batch',
    () async {
      final source = await addTestSource();
      final sync = CatalogSyncService(db);
      await sync.syncAll(source);
      final programme = goodGuide.substring(4, goodGuide.length - 5);
      xml = '<tv>${List.filled(2001, programme).join()}';
      guideRequested = Completer<void>();
      allowGuide = Completer<void>();
      responses['get_vod_streams'] = [];
      // The guide failure is expected: capture its log instead of printing it.
      final logs = <String>[];
      final print = debugPrint;
      debugPrint = (message, {wrapWidth}) => logs.add(message ?? '');
      addTearDown(() => debugPrint = print);
      final refresh = sync.syncAll(source);
      await guideRequested!.future;
      try {
        expect(await db.watchMovies(source.id).first, isEmpty);
        expect(
          (await db.select(db.epgProgrammes).get()).single.title,
          'Last good guide',
        );
      } finally {
        allowGuide!.complete();
        await refresh;
      }
      expect(logs, [contains('Missing </tv>')]);
      expect(
        (await db.select(db.epgProgrammes).get()).single.title,
        'Last good guide',
      );
    },
  );

  test(
    'partial conditional responses publish only changed sections and failed versions are retried',
    () async {
      final source = await addTestSource();
      final sync = CatalogSyncService(db);
      tags = {for (final action in responses.keys) action: '"one"'};
      await sync.syncAll(source);
      tags['get_vod_streams'] = '"two"';
      responses['get_vod_streams'] = [];
      tags['get_series'] = '"broken"';
      responses['get_series'] = {'error': 'outage'};
      await expectLater(sync.syncAll(source), throwsFormatException);
      expect((await db.watchMovies(source.id).first).single.streamId, 201);
      tags['get_series'] = '"one"';
      await sync.syncAll(source);
      expect(conditionalRequests['get_vod_streams'], '"one"');
      expect((await db.watchSeries(source.id).first).single.seriesId, 301);
      expect(await db.watchMovies(source.id).first, isEmpty);
      await sync.syncAll(source);
      expect(conditionalRequests['get_vod_streams'], '"two"');
      expect(
        await db.watchCategories(source.id, CatalogKind.live).first,
        hasLength(2),
      );
      expect(
        (await db.select(db.epgProgrammes).get()).single.title,
        'Last good guide',
      );
    },
  );

  test(
    'first M3U sync uses the discovered guide without changing provisioned settings',
    () async {
      final base = 'http://127.0.0.1:${server.port}';
      tags['/list.m3u'] = '"list"';
      playlist =
          '#EXTM3U url-tvg="$base/xmltv.php"\n#EXTINF:-1 tvg-id="news24.example",News\n$base/news.ts';
      await db.insertSource(
        SourcesCompanion.insert(
          name: 'test',
          sourceType: const Value(SourceType.m3u),
          serverUrl: '$base/list.m3u',
          username: '',
          password: '',
        ),
      );
      final source = (await db.watchActiveSource().first)!;
      await CatalogSyncService(db).syncAll(source);
      expect(
        (await db.select(db.epgProgrammes).get()).single.title,
        'Last good guide',
      );
      final current = (await db.watchActiveSource().first)!;
      expect(current.epgUrl, isNull);
      expect(current.discoveredEpgUrl, '$base/xmltv.php');
      xml = goodGuide.replaceFirst('Last good guide', 'Updated guide');
      await CatalogSyncService(db).syncAll(current);
      expect(conditionalRequests['/list.m3u'], '"list"');
      expect(
        (await db.select(db.epgProgrammes).get()).single.title,
        'Updated guide',
      );
    },
  );

  test('stream URL builders embed credentials and extension', () {
    final api = XtreamApi(
      XtreamCredentials(
        serverUrl: 'http://example.com:8080/',
        username: 'user',
        password: 'pass',
      ),
    );
    expect(
      api.liveStreamUrl(101),
      'http://example.com:8080/live/user/pass/101.ts',
    );
    expect(
      api.movieUrl(201, 'mkv'),
      'http://example.com:8080/movie/user/pass/201.mkv',
    );
    expect(
      api.seriesEpisodeUrl(301, null),
      'http://example.com:8080/series/user/pass/301.mp4',
    );
  });
}
