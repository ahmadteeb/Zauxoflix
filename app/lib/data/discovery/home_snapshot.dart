import 'package:drift/drift.dart' show Variable;
import '../db/app_database.dart';
import 'home_catalog.dart';
import 'home_ranking.dart';

Map<String, dynamic> packPick(HomePick p) {
  final w = p.work, r = w.imdb;
  return {
    'k': w.kind.name,
    'id': w.id,
    'title': w.name,
    'year': w.year,
    'external': w.external,
    'art': w.art,
    'plot': w.plot,
    'genres': p.genres.toList(),
    'category': p.categoryKey,
    'score': p.score,
    'why': p.reason,
    if (r != null) 'imdb': [r.id, r.score, r.votes],
    if (p.becauseOf case final s?) 'seed': [s.$1.$1.name, s.$1.$2, s.$2.name],
  };
}

HomePick unpackPick(Map<String, dynamic> row) {
  final genres = (row['genres'] as List).cast<String>().toSet(),
      category = row['category'] as String;
  final w = LibraryWork(
    CatalogKind.values.byName(row['k'] as String),
    row['id'] as int,
    row['title'] as String,
    year: row['year'] as int?,
    art: row['art'] as String?,
    plot: row['plot'] as String?,
    external: row['external'] as String?,
    category: category,
  );
  if (row['imdb'] case final List<Object?> r) {
    w.imdb = (
      id: r[0] as String,
      score: (r[1] as num?)?.toDouble(),
      votes: r[2] as int,
      genres: genres.toList(),
      year: w.year,
    );
  }
  final s = row['seed'] as List<Object?>?;
  return HomePick(
    w,
    (row['score'] as num).toDouble(),
    row['why'] as String,
    genres,
    category,
    s == null
        ? null
        : (
            (CatalogKind.values.byName(s[0] as String), s[1] as int),
            HomeSignal.values.byName(s[2] as String),
          ),
  );
}

Map<String, dynamic> packHome(HomeFeed feed) => {
  'movies': feed.movies.map(packPick).toList(),
  'series': feed.series.map(packPick).toList(),
  'featured': feed.featured.map(packPick).toList(),
};
HomeFeed unpackHome(Map<String, dynamic> data) {
  List<HomePick> picks(String key) =>
      (data[key] as List).cast<Map<String, dynamic>>().map(unpackPick).toList();
  return (
    movies: picks('movies'),
    series: picks('series'),
    featured: picks('featured'),
  );
}

// Validate the small cached shortlist against the current playlist. Numeric
// provider IDs can be reassigned to another title during a playlist refresh.
Future<Map<HomeId, String>> homeCatalogNames(
  AppDatabase db,
  int source,
  Iterable<HomeId> keys,
) async {
  final result = <HomeId, String>{};
  for (final kind in [CatalogKind.vod, CatalogKind.series]) {
    final ids = keys.where((k) => k.$1 == kind).map((k) => k.$2).toSet();
    if (ids.isEmpty) continue;
    final series = kind == CatalogKind.series,
        table = series ? 'series_items' : 'movies',
        id = series ? 'series_id' : 'stream_id';
    final rows = await db
        .customSelect(
          'SELECT $id AS item,name FROM $table WHERE source_id=? AND $id IN (${List.filled(ids.length, '?').join(',')})',
          variables: [Variable.withInt(source), ...ids.map(Variable.withInt)],
        )
        .get();
    for (final r in rows) {
      result[(kind, r.read<int>('item'))] = r.read<String>('name');
    }
  }
  return result;
}

HomeFeed filterHome(
  HomeFeed feed,
  List<HomeActivity> activity,
  Map<HomeId, String> catalog,
) {
  final known = {for (final a in activity) a.key},
      signals = {for (final a in activity) (a.key, a.signal)};
  List<HomePick> eligible(List<HomePick> picks, int limit) => [
    for (final p in picks)
      if (!known.contains(p.work.key) && catalog[p.work.key] == p.title)
        if (p.becauseOf != null && !signals.contains(p.becauseOf))
          HomePick(
            p.work,
            p.score,
            'From your library',
            p.genres,
            p.categoryKey,
          )
        else
          p,
  ].take(limit).toList();
  final movies = eligible(feed.movies, 24), series = eligible(feed.series, 24);
  final featured = eligible(feed.featured, 6);
  final seen = {for (final p in featured) p.work.key};
  for (final p in [...movies, ...series]) {
    if (featured.length >= 6) break;
    if (seen.add(p.work.key)) featured.add(p);
  }
  return (movies: movies, series: series, featured: featured);
}
