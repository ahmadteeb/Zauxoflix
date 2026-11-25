import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Variable, TableUpdateQuery;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/media_item.dart';
import '../db/app_database.dart';
import '../providers.dart';
import 'chart_sources.dart';
import 'daily_cache.dart';
import 'discovery_repository.dart';
import 'title_identity.dart';
import 'trakt_client.dart';

final chartCountryProvider = AsyncNotifierProvider<ChartCountry, String>(
  ChartCountry.new,
);

class ChartCountry extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(
        'chart.country',
      );
      if (saved == 'world' || chartRegions.containsKey(saved)) return saved!;
    } catch (_) {
      /* A device can still choose a country for this session. */
    }
    return 'JO';
  }

  Future<void> select(String code) async {
    if (code != 'world' && !chartRegions.containsKey(code)) return;
    state = AsyncData(code);
    try {
      await (await SharedPreferences.getInstance()).setString(
        'chart.country',
        code,
      );
    } catch (_) {}
  }
}

final chartSourcesProvider = Provider<ChartSources>((ref) {
  final http = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'User-Agent': 'Zauxoflix/1.0'},
    ),
  );
  ref.onDispose(() => http.close());
  final api = ref.watch(discoveryClientProvider);
  return ChartSources(http, api is TraktClient ? api : null);
});
typedef ChartQuery = ({
  int source,
  String region,
  ChartPeriod period,
  CatalogKind kind,
});
typedef ChartResult = ({
  List<ChartEntry> entries,
  int publishedCount,
  String provider,
  String day,
  String? through,
  String? month,
});

class ChartEntry extends MediaItem {
  ChartEntry({
    required String name,
    required CatalogKind kind,
    required int rank,
    required int localId,
    int? year,
    String? art,
  }) : super(
         title: name,
         id: localId,
         imageUrl: art,
         type: kind == CatalogKind.series ? MediaType.series : MediaType.movie,
         chartRank: rank,
         subtitle: year?.toString() ?? '',
       );
}

CacheId chartCacheKey(ChartQuery q) {
  final global = q.region == 'world';
  return (
    source: 0,
    slot: q.period == ChartPeriod.month
        ? 'netflix.month.v1/${global ? 'world' : 'countries'}'
        : global
        ? 'trakt.day.v1/${q.kind.name}'
        : 'apple.day.v1/${q.region}',
  );
}

final _catalogRevision = StreamProvider.autoDispose.family<int, CatalogKind>((
  ref,
  kind,
) {
  final db = ref.watch(databaseProvider);
  var revision = 0;
  return db
      .tableUpdates(
        TableUpdateQuery.onTable(
          kind == CatalogKind.series ? db.seriesItems : db.movies,
        ),
      )
      .map((_) => ++revision);
});

final topChartProvider = FutureProvider.autoDispose
    .family<ChartResult, ChartQuery>((ref, q) async {
      final day = ref.watch(recommendationDayProvider),
          cache = ref.watch(dailyCacheProvider);
      final api = ref.watch(chartSourcesProvider),
          db = ref.watch(databaseProvider);
      ref.watch(_catalogRevision(q.kind));
      final global = q.region == 'world',
          monthly = q.period == ChartPeriod.month;
      final data = await cache.get(
        chartCacheKey(q),
        day,
        (old) => monthly
            ? api.monthly(day, old, global: global)
            : global
            ? api.dailyGlobal(q.kind)
            : api.dailyRegion(q.region),
        allowStale: true,
      );
      final provider = monthly
          ? 'Netflix'
          : global
          ? 'Trakt'
          : 'Apple TV';
      final group = '${q.region}/${q.kind.name}';
      final values =
          (monthly
                  ? (data.data['charts'] as Json)[group]
                  : global
                  ? data.data['items']
                  : data.data[q.kind.name])
              as List? ??
          const [];
      final entries = await Future.wait(
        values
            .take(10)
            .cast<Json>()
            .indexed
            .map((row) => _entry(db, q, row.$2, row.$1 + 1)),
      );
      if (ref.mounted) {
        final timer = Timer(const Duration(minutes: 3), ref.keepAlive().close);
        ref.onDispose(timer.cancel);
      }
      return (
        entries: entries.whereType<ChartEntry>().toList(),
        publishedCount: entries.length,
        provider: provider,
        day: data.day,
        through: monthly
            ? (data.data['through'] as Json)[group] as String?
            : null,
        month: monthly ? data.data['month'] as String? : null,
      );
    }, retry: (_, _) => null);

final _endYear = RegExp(r'\s+((?:19|20)\d{2})$');
Future<ChartEntry?> _entry(
  AppDatabase db,
  ChartQuery q,
  Json chart,
  int rank,
) async {
  final name = chart['name'] as String,
      norm = discoveryName(name),
      year = chart['year'] as int?;
  final imdb = validImdb(chart['imdb']),
      tmdb = chart['tmdb'] == null ? null : 'tmdb:${chart['tmdb']}';
  final series = q.kind == CatalogKind.series,
      table = series ? 'series_items' : 'movies',
      id = series ? 'series_id' : 'stream_id',
      art = series ? 'cover' : 'icon';
  final rows = await db
      .customSelect(
        """
    SELECT $id AS id,name,release_year,external_id,$art AS art
    FROM $table INDEXED BY ${table}_external_id
    WHERE source_id=?1 AND external_id IN (?2,?3)
    UNION
    SELECT $id AS id,name,release_year,external_id,$art AS art
    FROM $table INDEXED BY ${table}_discovery_name
    WHERE source_id=?1 AND match_name=?4
    UNION
    SELECT $id AS id,name,release_year,external_id,$art AS art
    FROM $table INDEXED BY ${table}_discovery_name
    WHERE source_id=?1 AND match_name>=?5 AND match_name<?6
    ORDER BY id LIMIT 80
  """,
        variables: [
          Variable.withInt(q.source),
          Variable.withString(imdb ?? ''),
          Variable.withString(tmdb ?? ''),
          Variable.withString(norm),
          Variable.withString('$norm '),
          Variable.withString('$norm!'),
        ],
      )
      .get();
  final matches =
      <({int id, String? art, int? year, int confidence, String identity})>[];
  for (final r in rows) {
    final ext = r.readNullable<String>('external_id'),
        local = r.read<String>('name');
    final localYear =
        r.readNullable<int>('release_year') ??
        splitTitle(local).year ??
        int.tryParse(_endYear.firstMatch(local)?[1] ?? '');
    final direct = ext != null && (ext == imdb || ext == tmdb);
    if (!direct) {
      if (ext != null &&
          (imdb != null && ext.startsWith('tt') ||
              tmdb != null && ext.startsWith('tmdb:'))) {
        continue;
      }
      if (year != null && localYear != null && year != localYear) continue;
      final normalized = discoveryName(local),
          bare = normalized.replaceFirst(_endYear, '');
      if (normalized != norm && bare != norm) continue;
    }
    matches.add((
      id: r.read<int>('id'),
      art: r.readNullable<String>('art'),
      year: localYear,
      confidence: direct
          ? 3
          : year != null && year == localYear
          ? 2
          : 1,
      identity:
          ext ??
          (localYear == null
              ? 'local/${r.read<int>('id')}'
              : '$norm/$localYear'),
    ));
  }
  matches.sort((a, b) => b.confidence.compareTo(a.confidence));
  final best = matches.firstOrNull;
  final unique =
      best != null &&
      matches
              .where((m) => m.confidence == best.confidence)
              .map((m) => m.identity)
              .toSet()
              .length ==
          1;
  if (!unique) return null;
  return ChartEntry(
    name: name,
    kind: q.kind,
    rank: rank,
    year: best.year ?? year,
    localId: best.id,
    art: (chart['art'] as String?) ?? best.art,
  );
}
