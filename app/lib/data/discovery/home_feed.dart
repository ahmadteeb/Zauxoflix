import 'dart:async';

import 'package:drift/drift.dart' show Variable, TableUpdateQuery, UpdateKind;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_platform.dart';
import '../db/app_database.dart';
import '../providers.dart';
import 'discovery_repository.dart';
import 'daily_cache.dart';
import 'home_snapshot.dart';
import 'home_catalog.dart';
import 'home_ranking.dart';
import 'imdb_asset.dart';
import 'trakt_client.dart';

final homeActivityProvider = StreamProvider.autoDispose
    .family<List<HomeActivity>, int>((ref, source) {
      final db = ref.watch(databaseProvider);
      return db
          .customSelect(
            """
    SELECT kind,item_id AS item,'saved' AS reason,added_at AS stamp,0.0 AS progress
      FROM favorites WHERE source_id=?1 AND kind IN ('vod','series')
    UNION ALL
    SELECT CASE kind WHEN 'movie' THEN 'vod' ELSE 'series' END,
      CASE kind WHEN 'movie' THEN item_id ELSE series_id END,
      CASE WHEN kind='episode' AND ((duration_secs>0 AND position_secs>=duration_secs)
        OR (duration_secs=0 AND position_secs=0)) THEN 'watched' ELSE 'watching' END,
      updated_at, CASE WHEN duration_secs>0 THEN 1.0*position_secs/duration_secs ELSE 0.0 END
      FROM playback_positions WHERE source_id=?1 AND (kind='movie' OR series_id IS NOT NULL)
      AND (position_secs>0 OR (kind='episode' AND duration_secs=0 AND position_secs=0))
    UNION ALL SELECT kind,item_id,'watched',watched_at,1.0 FROM watched_titles WHERE source_id=?1
    ORDER BY stamp DESC,item DESC
  """,
            variables: [Variable.withInt(source)],
            readsFrom: {db.favorites, db.playbackPositions, db.watchedTitles},
          )
          .watch()
          .map((rows) {
            final seen = <(HomeId, HomeSignal)>{};
            final events = <HomeActivity>[];
            for (final r in rows) {
              final key = (
                CatalogKind.values.byName(r.read<String>('kind')),
                r.read<int>('item'),
              );
              final signal = HomeSignal.values.byName(r.read<String>('reason'));
              if (seen.add((key, signal))) {
                events.add((
                  key: key,
                  signal: signal,
                  stamp: r.read<int>('stamp') ~/ 3600 * 3600,
                  progress:
                      (r.read<double>('progress').clamp(0, 1) * 10).round() /
                      10,
                ));
              }
            }
            return events;
          })
          .distinct(
            (a, b) =>
                a.length == b.length &&
                a.indexed.every((pair) => pair.$2 == b[pair.$1]),
          );
    });

final homeIndexPathProvider = imdbIndexPathProvider;

typedef HomeRankingLoader =
    Future<HomeFeed> Function(
      List<HomeActivity> activity,
      Map<HomeId, TitleDiscovery> extras,
      DateTime day,
      int seed,
      Map<String, int> exposure,
    );

final homeRankingLoaderProvider = Provider.autoDispose
    .family<HomeRankingLoader, int>((ref, source) {
      final db = ref.watch(databaseProvider);
      final path = ref.read(homeIndexPathProvider.future);
      return (activity, extras, day, seed, exposure) async {
        final index = await path;
        final request = (
          source: source,
          index: index,
          activity: activity,
          extras: extras,
          day: day,
          seed: seed,
          exposure: exposure,
        );
        if (!isWebOsPlatform && index == null) {
          final count = await db
              .customSelect(
                'SELECT (SELECT count(*) FROM movies WHERE source_id=?1)+(SELECT count(*) FROM series_items WHERE source_id=?1) AS n',
                variables: [Variable.withInt(source)],
              )
              .getSingle();
          if (count.read<int>('n') < 800) {
            return _loadRankedHome(db, request);
          }
        }
        // Only the ranked shortlist crosses isolates. The catalog, title
        // matching and scoring all stay together in the worker.
        return _loadRankedHomeInWorker(db, request);
      };
    });

typedef _HomeRankingRequest = ({
  int source,
  String? index,
  List<HomeActivity> activity,
  Map<HomeId, TitleDiscovery> extras,
  DateTime day,
  int seed,
  Map<String, int> exposure,
});

Future<HomeFeed> _loadRankedHomeInWorker(
  AppDatabase db,
  _HomeRankingRequest request,
) => db.computeWithDatabase(
  connect: AppDatabase.connect,
  computation: (worker) => _loadRankedHome(worker, request),
);

Future<HomeFeed> _loadRankedHome(
  AppDatabase db,
  _HomeRankingRequest request,
) async => rankHome(
  await loadHomeCatalog(db, request.source, request.index),
  request.activity,
  request.extras,
  request.day,
  daySeed: request.seed,
  recentFeatures: request.exposure,
  limit: 48,
);

final homeRefreshDelayProvider = Provider<Duration>(
  (_) => isWebOsPlatform ? const Duration(milliseconds: 1250) : Duration.zero,
);

/// Limit online enrichment to one recent title from each activity type. The
/// offline feed renders independently and stays usable during network failures.
Future<Map<HomeId, TitleDiscovery>> _extras(
  DiscoveryRepository repo,
  int source,
  List<HomeActivity> activities,
) async {
  if (repo.client == null) return {};
  final seeds = <HomeId>{};
  for (final signal in HomeSignal.values) {
    final seed = activities
        .where((a) => a.signal == signal && !seeds.contains(a.key))
        .firstOrNull;
    if (seed != null) seeds.add(seed.key);
  }
  final found = <HomeId, TitleDiscovery>{};
  await Future.wait(
    seeds.map((seed) async {
      try {
        CatalogTitle? key;
        if (seed.$1 == CatalogKind.vod) {
          final row = await repo.db.getMovie(source, seed.$2);
          if (row != null) key = movieKey(row);
        } else {
          final row = await repo.db.getSeriesItem(source, seed.$2);
          if (row != null) key = seriesKey(row);
        }
        if (key == null) return;
        final details = await repo.load(key);
        if (details != null) found[seed] = details;
      } on Exception {
        return;
      }
    }),
  );
  return found;
}

final _catalogEdits = StreamProvider.autoDispose<int>((ref) {
  final db = ref.watch(databaseProvider);
  var revision = 0;
  return db
      .tableUpdates(
        TableUpdateQuery.allOf([
          TableUpdateQuery.onAllTables([db.movies, db.seriesItems]),
          TableUpdateQuery.onTable(
            db.recommendationSnapshots,
            limitUpdateKind: UpdateKind.delete,
          ),
        ]),
      )
      .map((_) => ++revision);
});

final _storedHome = FutureProvider.autoDispose.family<HomeFeed, int>((
  ref,
  source,
) async {
  final day = ref.watch(recommendationDayProvider);
  final store = ref.watch(dailyCacheProvider),
      repo = ref.watch(discoveryRepositoryProvider);
  ref.watch(_catalogEdits);
  final delay = ref.watch(homeRefreshDelayProvider);
  final snapshot = await store.get(
    (source: source, slot: 'home.v1'),
    day,
    (previous) async {
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      if (!ref.mounted) throw StateError('Home refresh left the screen');
      final rank = ref.read(homeRankingLoaderProvider(source));
      final events = await ref.read(homeActivityProvider(source).future);
      final enrich = await _extras(repo, source, events);
      final now = DateTime.parse(day),
          dayNumber =
              DateTime.utc(
                now.year,
                now.month,
                now.day,
              ).millisecondsSinceEpoch ~/
              86400000;
      final exposure = <String, int>{};
      if (previous?.data['exposure'] case final Map<String, dynamic> seen) {
        for (final e in seen.entries) {
          final value = e.value;
          if (value is int && value >= dayNumber - 3 && value < dayNumber) {
            exposure[e.key] = value;
          }
        }
      }
      final seed = dayNumber * 65537 + source;
      final feed = await rank(events, enrich, now, seed, exposure);
      for (final p in feed.featured) {
        exposure['${p.work.kind.name}/${p.work.identity}'] = dayNumber;
      }
      return {...packHome(feed), 'exposure': exposure};
    },
    persist: (d) =>
        (d['movies'] as List).isNotEmpty || (d['series'] as List).isNotEmpty,
  );
  return unpackHome(snapshot.data);
});
final homeFeedProvider = FutureProvider.autoDispose.family<HomeFeed, int>((
  ref,
  source,
) async {
  final db = ref.watch(databaseProvider);
  final stored = ref.watch(_storedHome(source).future);
  final events = ref.watch(homeActivityProvider(source).future);
  final feed = await stored;
  final keys = [
    ...feed.movies,
    ...feed.series,
    ...feed.featured,
  ].map((p) => p.work.key);
  final catalog = await homeCatalogNames(db, source, keys);
  return filterHome(feed, await events, catalog);
});

final _quickFeed = FutureProvider.autoDispose.family<HomeFeed, int>((
  ref,
  source,
) async {
  final db = ref.watch(databaseProvider), cache = ref.watch(dailyCacheProvider);
  final day = ref.watch(recommendationDayProvider);
  ref.watch(_catalogEdits);
  final events = ref.watch(homeActivityProvider(source).future);
  final saved = await cache.read((source: source, slot: 'home.v1'));
  if (!ref.mounted) return emptyHomeFeed;
  final activity = await events;
  if (saved != null) {
    final feed = unpackHome(saved.data);
    final catalog = await homeCatalogNames(
      db,
      source,
      [...feed.movies, ...feed.series, ...feed.featured].map((p) => p.work.key),
    );
    return filterHome(feed, activity, catalog);
  }
  return _rankQuickHome(db, source, activity, DateTime.parse(day));
});

Future<HomeFeed> _rankQuickHome(
  AppDatabase db,
  int source,
  List<HomeActivity> activity,
  DateTime day,
) {
  Future<HomeFeed> preview(AppDatabase db) async => rankHome(
    await loadHomeCatalog(
      db,
      source,
      null,
      previewSeeds: activity.map((a) => a.key).toList(),
    ),
    activity,
    {},
    day,
  );
  return isWebOsPlatform
      ? db.computeWithDatabase(
          connect: AppDatabase.connect,
          computation: preview,
        )
      : preview(db);
}

final homeDisplayFeedProvider = Provider.autoDispose.family<HomeFeed?, int>((
  ref,
  source,
) {
  final full = ref.watch(homeFeedProvider(source)).value;
  return full ?? ref.watch(_quickFeed(source)).value;
});

final homeBackdropProvider = FutureProvider.autoDispose
    .family<String?, (CatalogKind, String)>((ref, key) async {
      final client = ref.watch(discoveryClientProvider);
      if (client is! TraktClient) return null;
      final art = await client.spotlightImage(key.$1, key.$2);
      if (ref.mounted) {
        final timer = Timer(const Duration(minutes: 15), ref.keepAlive().close);
        ref.onDispose(timer.cancel);
      }
      return art;
    }, retry: (_, _) => null);
