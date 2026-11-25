import 'dart:convert';
import 'dart:isolate';

import 'package:dio/dio.dart';
import '../db/app_database.dart';
import 'daily_cache.dart';
import 'trakt_client.dart';

enum ChartPeriod { today, month }

const chartRegions = {
  'JO': 'Jordan',
  'US': 'United States',
  'SA': 'Saudi Arabia',
  'AE': 'United Arab Emirates',
  'EG': 'Egypt',
  'GB': 'United Kingdom',
  'TR': 'Türkiye',
  'IN': 'India',
  'CA': 'Canada',
  'AU': 'Australia',
  'DE': 'Germany',
  'FR': 'France',
  'MX': 'Mexico',
  'BR': 'Brazil',
  'JP': 'Japan',
  'KR': 'South Korea',
};

Uri? _https(Object? value, String domain) {
  final uri = value is String ? Uri.tryParse(value) : null;
  return uri != null &&
          uri.scheme == 'https' &&
          uri.userInfo.isEmpty &&
          !uri.hasPort &&
          (uri.host == domain || uri.host.endsWith('.$domain'))
      ? uri
      : null;
}

/// Read only the two explicitly ranked shelves on the public storefront.
Json appleCharts(String page, String region) {
  final script = RegExp(
    r'<script\b(?=[^>]*\bid=["\x27]serialized-server-data["\x27])[^>]*>([\s\S]*?)</script>',
    caseSensitive: false,
  ).firstMatch(page);
  if (script == null) throw const FormatException('Missing Apple TV charts');
  final root = jsonDecode(script[1]!);
  final out = <String, dynamic>{};
  void visit(Object? node) {
    if (node is List) {
      for (final v in node) {
        visit(v);
      }
      return;
    }
    if (node is! Json) return;
    final id = node['id'], items = node['items'];
    if (id is String && node[r'$type'] == 'chart' && items is List) {
      final kind = id.contains('.ChartsMovies.')
          ? 'vod'
          : id.contains('.ChartsShows.')
          ? 'series'
          : null;
      if (kind == null) return;
      final chart = <Json>[];
      for (final item in items.take(10).whereType<Json>()) {
        final action = item['contextAction'], artwork = item['artwork'];
        if (action is! Json || action['title'] is! String) {
          throw const FormatException('Invalid Apple chart entry');
        }
        final link = _https(action['url'], 'tv.apple.com');
        if (link == null ||
            link.pathSegments.firstOrNull != region.toLowerCase()) {
          throw const FormatException('Unexpected Apple storefront');
        }
        final art = artwork is Json ? artwork['template'] : null;
        final image = art is String
            ? art
                  .replaceAll('{w}', '360')
                  .replaceAll('{h}', '540')
                  .replaceAll('{f}', 'jpg')
            : null;
        chart.add({
          'name': action['title'],
          'url': link.replace(queryParameters: {}).toString(),
          'art': _https(image, 'mzstatic.com')?.toString(),
        });
      }
      out[kind] = chart;
      return;
    }
    for (final v in node.values) {
      if (v is List || v is Map) visit(v);
    }
  }

  visit(root);
  if (out.isEmpty) {
    throw const FormatException('Apple TV did not publish a chart');
  }
  return out;
}

class _Standing {
  final weekly = <String, int>{};
  int newestRank = 11;
  String newestWeek = '';
}

Future<Json> netflixMonth(
  Stream<String> lines,
  String day, {
  required bool global,
}) async {
  final month = day.substring(0, 7);
  final groups = <String, Map<String, _Standing>>{},
      through = <String, String>{};
  Map<String, int>? header;
  await for (final line in lines) {
    if (line.trim().isEmpty) continue;
    final cells = line.split('\t');
    if (header == null) {
      header = {for (final (i, name) in cells.indexed) name.trim(): i};
      for (final key in [
        'week',
        'category',
        'show_title',
        'weekly_rank',
        global ? 'weekly_views' : 'country_iso2',
      ]) {
        if (!header.containsKey(key)) {
          throw const FormatException('Netflix chart columns changed');
        }
      }
      continue;
    }
    String field(String key) => cells[header![key]!].trim();
    final week = field('week');
    if (!week.startsWith(month) || week.compareTo(day) > 0) continue;
    final category = field('category'),
        rank = int.tryParse(field('weekly_rank')),
        name = field('show_title');
    final kind = category.startsWith('Films')
        ? 'vod'
        : category.startsWith('TV')
        ? 'series'
        : null;
    if (kind == null || name.isEmpty || rank == null || rank < 1 || rank > 10) {
      continue;
    }
    final country = global ? 'world' : field('country_iso2').toUpperCase();
    final key = '$country/$kind';
    final standing = groups
        .putIfAbsent(key, () => {})
        .putIfAbsent(name, _Standing.new);
    final votes = global ? int.tryParse(field('weekly_views')) : 11 - rank;
    if (votes == null) continue;
    // Global views add across seasons. Country data publishes rank only.
    // Count each series' single best placement per reporting week.
    final prior = standing.weekly[week] ?? 0;
    standing.weekly[week] = global
        ? prior + votes
        : (votes > prior ? votes : prior);
    if (week.compareTo(standing.newestWeek) > 0 ||
        (week == standing.newestWeek && rank < standing.newestRank)) {
      standing.newestWeek = week;
      standing.newestRank = rank;
    }
    if (week.compareTo(through[key] ?? '') > 0) through[key] = week;
  }
  if (header == null) throw const FormatException('Empty Netflix report');
  final charts = <String, dynamic>{};
  for (final g in groups.entries) {
    int total(_Standing s) => s.weekly.values.fold(0, (a, b) => a + b);
    final titles =
        g.value.entries.where((e) => e.value.weekly.isNotEmpty).toList()
          ..sort((a, b) {
            final score = total(b.value).compareTo(total(a.value));
            if (score != 0) return score;
            final week = b.value.newestWeek.compareTo(a.value.newestWeek);
            if (week != 0) return week;
            final rank = a.value.newestRank.compareTo(b.value.newestRank);
            return rank != 0 ? rank : a.key.compareTo(b.key);
          });
    charts[g.key] = [
      for (final e in titles.take(10))
        {
          'name': e.key,
          'url': Uri.https('www.netflix.com', '/search', {
            'q': e.key,
          }).toString(),
        },
    ];
  }
  return {'charts': charts, 'through': through, 'month': month};
}

class ChartSources {
  ChartSources(this.http, this.trakt);
  final Dio http;
  final TraktClient? trakt;
  Future<Json> dailyGlobal(CatalogKind kind) async {
    final api = trakt;
    if (api == null) throw StateError('Trakt is unavailable');
    final items = await api.dailyChart(kind);
    if (items.isEmpty) throw const FormatException('Empty Trakt chart');
    return {'items': items};
  }

  Future<Json> dailyRegion(String region) async {
    if (!chartRegions.containsKey(region)) throw ArgumentError.value(region);
    final result = await http.get<String>(
      'https://tv.apple.com/${region.toLowerCase()}',
      options: Options(
        responseType: ResponseType.plain,
        headers: {'Accept-Language': 'en'},
      ),
    );
    return _appleChartsInWorker(result.data ?? '', region);
  }

  Future<Json> monthly(
    String day,
    Snapshot? previous, {
    required bool global,
  }) async {
    final old = previous?.data;
    final sameMonth = old?['month'] == day.substring(0, 7);
    final modified = sameMonth && old != null
        ? (old['modified'] as String?)
        : null;
    final fresh = await _monthInWorker(day, global, modified);
    return fresh ?? old!;
  }
}

Future<Json> _appleChartsInWorker(String page, String region) =>
    Isolate.run(() => appleCharts(page, region));

// The country archive contains historical data for all markets. Stream and
// aggregate it off the UI isolate, then return just this month's chart rows.
Future<Json?> _monthInWorker(String day, bool global, String? modified) =>
    Isolate.run(() => _fetchMonth(day, global, modified));
Future<Json?> _fetchMonth(String day, bool global, String? modified) async {
  final http = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 40),
    ),
  );
  try {
    final response = await http.get<ResponseBody>(
      'https://www.netflix.com/tudum/top10/data/all-weeks-${global ? 'global' : 'countries'}.tsv',
      options: Options(
        responseType: ResponseType.stream,
        headers: {'If-Modified-Since': ?modified},
        validateStatus: (s) => s == 200 || s == 304,
      ),
    );
    if (response.statusCode == 304 && modified != null) return null;
    final rows = response.data!.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    final data = await netflixMonth(rows, day, global: global);
    data['modified'] = response.headers.value('last-modified');
    return data;
  } finally {
    http.close();
  }
}
