import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:sqlite3/sqlite3.dart' as sql;

import '../../core/app_platform.dart';
import '../db/app_database.dart';
import 'title_identity.dart';
import 'trakt_client.dart';

typedef HomeId = (CatalogKind, int);
typedef HomeRating = ({
  String id,
  double? score,
  int votes,
  List<String> genres,
  int? year,
});

final _trailingYear = RegExp(r'^(.+)\s+((?:19|20)\d{2})$');
final _bilingual = RegExp(r'\s+[-|–—]\s+');
final _arabic = RegExp(r'[\u0600-\u06ff]');
final _edition = RegExp(r'\s+(مدبلج|مترجم)$');

class LibraryWork {
  LibraryWork(
    this.kind,
    this.id,
    this.name, {
    this.art,
    this.category = '',
    this.year,
    this.external,
    this.providerScore,
    this.plot,
    this.cached,
  }) {
    final clean = splitTitle(name.replaceFirst(_edition, ''));
    final suffix = _trailingYear.firstMatch(clean.name);
    year ??= cached?.year ?? clean.year ?? int.tryParse(suffix?[2] ?? '');
    final bare = suffix != null && suffix[2] == year.toString()
        ? suffix[1]!
        : clean.name;
    names = {
      bare,
      if (bare.contains(_bilingual) && _arabic.hasMatch(bare))
        ...bare.split(_bilingual),
      if (cached != null) cached!.name,
    }.map((s) => s.trim().toLowerCase()).where((s) => s.isNotEmpty).toSet();
    canonicalName = names.firstOrNull ?? name;
  }
  final CatalogKind kind;
  final int id;
  final String name, category;
  final String? art, external, plot;
  final double? providerScore;
  final TraktTitle? cached;
  int? year;
  late final Set<String> names;
  late final String canonicalName;
  HomeRating? imdb;
  HomeId get key => (kind, id);
  String? get imdbId => validImdb(external) ?? cached?.imdb ?? imdb?.id;
  String get identity => imdbId ?? external ?? '$canonicalName|$year';
}

Future<List<LibraryWork>> loadHomeCatalog(
  AppDatabase db,
  int source,
  String? index, {
  List<HomeId>? previewSeeds,
}) async {
  // The account database stays under Drift's normal connection. The IMDb index
  // is read-only. Only the temporary lookup table lives in the IMDb connection.
  final works = <LibraryWork>[];
  for (final kind in [CatalogKind.vod, CatalogKind.series]) {
    final series = kind == CatalogKind.series;
    final table = series ? 'series_items' : 'movies',
        id = series ? 'series_id' : 'stream_id';
    final art = series ? 'cover' : 'icon', plot = series ? 'c.plot' : 'NULL';
    final seedIds =
        previewSeeds
            ?.where((s) => s.$1 == kind)
            .map((s) => s.$2)
            .take(24)
            .toList() ??
        const <int>[];
    final recent = series ? 'last_modified_at' : 'added_at';
    final slots = [
      for (var i = 0; i < seedIds.length; i++) '?${i + 3}',
    ].join(',');
    // Serve a small, immediately available pool while the full catalog is matched to IMDb.
    final window = previewSeeds == null
        ? ''
        : """
      AND c.$id IN (
        SELECT $id FROM (SELECT $id FROM $table WHERE source_id=?1 ORDER BY $recent DESC LIMIT 80)
        ${seedIds.isEmpty ? '' : '''UNION SELECT $id FROM $table WHERE source_id=?1 AND $id IN ($slots)
        UNION SELECT $id FROM (SELECT $id FROM $table WHERE source_id=?1 AND category_id IN
          (SELECT category_id FROM $table WHERE source_id=?1 AND $id IN ($slots))
          ORDER BY $recent DESC LIMIT 100)'''}
      )
    """;
    final rows = await db
        .customSelect(
          """
      SELECT c.$id AS item,c.name,c.release_year,c.external_id,c.$art AS art,c.rating,c.rating_scale,
        $plot AS plot,g.name AS category,e.fingerprint,e.payload FROM $table c
        LEFT JOIN categories g ON g.source_id=c.source_id AND g.kind=?2 AND g.category_id=c.category_id
        LEFT JOIN discovery_entries e ON e.source_id=c.source_id AND e.kind=?2 AND e.item_id=c.$id
        WHERE c.source_id=?1 $window ORDER BY c.$id
    """,
          variables: [
            Variable.withInt(source),
            Variable.withString(kind.name),
            ...seedIds.map(Variable.withInt),
          ],
        )
        .get();
    for (final row in rows) {
      final name = row.read<String>('name'),
          year = row.readNullable<int>('release_year'),
          external = row.readNullable<String>('external_id');
      final payload = row.readNullable<String>('payload');
      TraktTitle? cached;
      if (payload != null && payload != 'null') {
        try {
          final stamp = jsonDecode(row.read<String>('fingerprint'));
          if (stamp is List &&
              stamp.length == 3 &&
              stamp.first == name &&
              (year == null || stamp[1] == null || stamp[1] == year) &&
              (external == null || stamp[2] == null || stamp[2] == external)) {
            final entry = jsonDecode(payload);
            cached = entry is Json ? TraktTitle.parse(entry['title']) : null;
            if (external != null && cached?.hasExternal(external) != true) {
              cached = null;
            }
          }
        } on FormatException {
          cached = null;
        } on TypeError {
          cached = null;
        }
      }
      final score = row.readNullable<double>('rating'),
          scale = row.readNullable<int>('rating_scale');
      works.add(
        LibraryWork(
          kind,
          row.read<int>('item'),
          name,
          art: row.readNullable<String>('art'),
          category: row.readNullable<String>('category') ?? '',
          year: year,
          external: external,
          providerScore:
              score != null &&
                  scale != null &&
                  scale > 0 &&
                  score > 0 &&
                  score <= scale
              ? score * 10 / scale
              : null,
          plot: row.readNullable<String>('plot'),
          cached: cached,
        ),
      );
    }
  }
  if (index != null && works.isNotEmpty && File(index).existsSync()) {
    try {
      readHomeRatings(index, works);
    } on sql.SqliteException {
      // A private index may be temporarily locked during an import.
    }
  }
  return works;
}

void readHomeRatings(String path, List<LibraryWork> works) {
  if (isWebOsPlatform) configureWebOsSqlite();
  final db = sql.sqlite3.open(path, mode: sql.OpenMode.readOnly);
  try {
    if (db.userVersion != 1) return;
    db.execute('PRAGMA temp_store=MEMORY');
    db.execute(
      'CREATE TEMP TABLE wanted(name TEXT,year INTEGER,series INTEGER,local INTEGER, PRIMARY KEY(name,year,series,local)) WITHOUT ROWID',
    );
    db.execute('CREATE TEMP TABLE exact(id INTEGER,local INTEGER)');
    final byName = db.prepare(
      'INSERT OR IGNORE INTO wanted VALUES(lower(?),?,?,?)',
    );
    final byId = db.prepare('INSERT INTO exact VALUES(?,?)');
    try {
      db.execute('BEGIN');
      for (var i = 0; i < works.length; i++) {
        final w = works[i];
        if (w.imdbId case final id?) {
          byId.execute([int.parse(id.substring(2)), i]);
        } else if (w.year != null) {
          for (final name in w.names) {
            byName.execute([
              name,
              w.year,
              w.kind == CatalogKind.series ? 1 : 0,
              i,
            ]);
          }
        }
      }
      db.execute('COMMIT');
    } finally {
      byName.dispose();
      byId.dispose();
    }
    const series = "t.kind IN ('tvSeries','tvMiniSeries')";
    const formats =
        "t.kind IN ('movie','tvMovie','video','tvSeries','tvMiniSeries')";
    // Collect all identities before reading ratings, so a rated remake or short
    // cannot win a title match merely because the other record lacks a rating.
    final hits = db.select("""
      WITH hits(local,id) AS (
        SELECT e.local,t.id FROM exact e JOIN titles t ON t.id=e.id
        UNION SELECT w.local,t.id FROM titles t CROSS JOIN wanted w
          ON w.name=lower(t.title) AND w.year=t.year AND w.series=($series) WHERE $formats
        UNION SELECT w.local,t.id FROM titles t CROSS JOIN wanted w
          ON w.name=lower(t.original) AND w.year=t.year AND w.series=($series) WHERE t.original IS NOT NULL AND $formats
      ), unique_match AS (SELECT local,min(id) AS id FROM hits GROUP BY local HAVING count(*)=1)
      SELECT m.local,t.id,t.kind,t.year,t.genres,r.score,r.votes FROM unique_match m JOIN titles t ON t.id=m.id
        LEFT JOIN ratings r ON r.id=t.id
    """);
    for (final row in hits) {
      final w = works[row['local'] as int];
      if ((w.kind == CatalogKind.series) !=
          ['tvSeries', 'tvMiniSeries'].contains(row['kind'])) {
        continue;
      }
      w.imdb = (
        id: 'tt${row['id'].toString().padLeft(7, '0')}',
        year: row['year'] as int?,
        score: (row['score'] as num?)?.toDouble(),
        votes: row['votes'] as int? ?? 0,
        genres: (row['genres'] as String? ?? '')
            .toLowerCase()
            .split(',')
            .where((s) => s.isNotEmpty)
            .toList(),
      );
      w.year ??= w.imdb!.year;
    }
  } finally {
    db.dispose();
  }
}
