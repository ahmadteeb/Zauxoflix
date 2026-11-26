// Prepare a private Flutter asset from a personal IMDb index and local library.
//
// dart run lib/data/discovery/imdb_prepare.dart --index <imdb.sqlite>
//     --library <zauxoflix.sqlite> --output-dir assets/private_imdb
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';
import 'title_identity.dart' show validImdb;

import 'imdb_cli_sqlite.dart';

final _prefix = RegExp(
  r'^\s*\[?(?:ar|en|fr|de|us|uk)\]?\s*[|:]\s*',
  caseSensitive: false,
);
final _edition = RegExp(r'\s+(مدبلج|مترجم)$');
final _suffix = RegExp(
  r'\s+(19\d{2}|20\d{2})$|\s*[\[(](19\d{2}|20\d{2})[\])]$|[\s._-]+(?:2160p|1080p|720p|4k|uhd|fhd|hd)$',
  caseSensitive: false,
);
final _arabic = RegExp(r'[؀-ۿ]');
final _bilingual = RegExp(r'\s+[-|–—]\s+');
final _assetName = RegExp(r'^imdb-[0-9a-f]{64}\.sqlite\.gz$');

/// IMDb ID saved by discovery, if the entry still describes this catalog row.
String? _cachedImdb(Row row) {
  final fingerprint = row['fingerprint'], payload = row['payload'];
  if (fingerprint is! String || payload is! String) return null;
  try {
    if (jsonDecode(fingerprint) case [
      final label,
      final savedYear,
      final savedId,
    ] when label == row['name']) {
      final year = row['release_year'], external = row['external_id'];
      if (year != null && savedYear != null && year != savedYear) return null;
      if (external != null && savedId != null && external != savedId) {
        return null;
      }
      if (jsonDecode(payload) case {'title': {'ids': {'imdb': final id}}}) {
        return validImdb(id);
      }
    }
  } on FormatException {
    // A damaged cache entry only loses this hint.
  }
  return null;
}

({Set<(String, int, int)> names, Set<int> exact}) _catalogKeys(
  Database library,
) {
  // The same conservative title/year/kind identity as Home. Keep all candidates
  // of an ambiguous title so the device can decline that match.
  final names = <(String, int, int)>{};
  final exact = <int>{};
  for (final (table, item, kind) in const [
    ('movies', 'stream_id', 'vod'),
    ('series_items', 'series_id', 'series'),
  ]) {
    final rows = library.select(
      '''SELECT c.name,c.release_year,c.external_id,e.fingerprint,e.payload
      FROM $table c LEFT JOIN discovery_entries e ON e.source_id=c.source_id
          AND e.kind=? AND e.item_id=c.$item''',
      [kind],
    );
    for (final row in rows) {
      var title = (row['name'] as String).replaceFirst(_prefix, '').trim();
      title = title.replaceFirst(_edition, '').trim();
      var year = row['release_year'] as int?;
      for (final id in [validImdb(row['external_id']), _cachedImdb(row)]) {
        if (id != null) exact.add(int.parse(id.substring(2)));
      }
      for (
        var match = _suffix.firstMatch(title);
        match != null && match.start > 0;
        match = _suffix.firstMatch(title)
      ) {
        final found = int.tryParse(match[1] ?? match[2] ?? '');
        if (year != null && found != null && year != found) break;
        year ??= found;
        title = title.substring(0, match.start).trim();
      }
      if (year == null) continue;
      for (final name in [
        title,
        if (title.contains(_arabic)) ...title.split(_bilingual),
      ]) {
        final alias = name.trim().toLowerCase();
        if (alias.isNotEmpty) {
          names.add((alias, year, kind == 'series' ? 1 : 0));
        }
      }
    }
  }
  return (names: names, exact: exact);
}

Future<({File asset, int count})> prepare(
  File index,
  File library,
  Directory directory,
) async {
  await directory.create(recursive: true);
  final catalog = sqlite3.open(library.path, mode: OpenMode.readOnly);
  final ({Set<(String, int, int)> names, Set<int> exact}) keys;
  try {
    keys = _catalogKeys(catalog);
  } finally {
    catalog.dispose();
  }
  final staging = await directory.createTemp('prepare-');
  try {
    final database = File('${staging.path}/index.sqlite');
    final int count;
    final db = sqlite3.open(database.path, uri: true);
    try {
      db.execute('ATTACH DATABASE ? AS imdb', [
        index.absolute.uri.replace(query: 'mode=ro').toString(),
      ]);
      if (db.select('PRAGMA imdb.user_version').single.values.single != 1) {
        throw const FormatException('Unsupported personal IMDb index');
      }
      db.execute('''
        PRAGMA journal_mode=OFF;
        PRAGMA synchronous=OFF;
        CREATE TEMP TABLE wanted(name,year,series,PRIMARY KEY(name,year,series)) WITHOUT ROWID;
        CREATE TEMP TABLE selected(id INTEGER PRIMARY KEY);
        BEGIN;
      ''');
      for (final (name, year, series) in keys.names) {
        db.execute('INSERT INTO wanted VALUES(?,?,?)', [name, year, series]);
      }
      for (final id in keys.exact) {
        db.execute('INSERT INTO selected VALUES(?)', [id]);
      }
      for (final field in ['title', 'original']) {
        db.execute(
          '''INSERT OR IGNORE INTO selected SELECT t.id FROM imdb.titles t CROSS JOIN wanted w
          ON w.name=lower(t.$field) AND w.year=t.year AND w.series=(t.kind IN ('tvSeries','tvMiniSeries'))
          WHERE t.kind IN ('movie','tvMovie','video','tvSeries','tvMiniSeries') AND t.$field IS NOT NULL''',
        );
      }
      for (final table in ['titles', 'ratings', 'cast_members', 'people']) {
        final schema = db.select(
          "SELECT sql FROM imdb.sqlite_master WHERE type='table' AND name=?",
          [table],
        );
        db.execute(schema.single['sql'] as String);
      }
      db.execute('''
        INSERT INTO titles SELECT * FROM imdb.titles WHERE id IN selected;
        INSERT INTO ratings SELECT * FROM imdb.ratings WHERE id IN selected;
        INSERT INTO cast_members SELECT * FROM imdb.cast_members WHERE title_id IN selected;
        INSERT INTO people SELECT * FROM imdb.people WHERE id IN (SELECT person_id FROM cast_members);
        CREATE INDEX cast_by_person ON cast_members(person_id,title_id);
        CREATE INDEX titles_by_year ON titles(year);
        PRAGMA user_version=1;
        COMMIT;
      ''');
      count =
          db.select('SELECT count(*) FROM titles').single.values.single as int;
      if (count == 0) {
        throw const FormatException(
          'No movie or series matched the selected library',
        );
      }
    } finally {
      db.dispose();
    }
    final compressed = File('${staging.path}/index.gz');
    await database
        .openRead()
        .transform(GZipCodec(level: 6).encoder)
        .pipe(compressed.openWrite());
    final digest = await sha256.bind(compressed.openRead()).first;
    final name = 'imdb-$digest.sqlite.gz';
    final asset = await compressed.rename('${directory.path}/$name');
    await for (final old in directory.list()) {
      final oldName = old.uri.pathSegments.last;
      if (old is File && oldName != name && _assetName.hasMatch(oldName)) {
        await old.delete();
      }
    }
    return (asset: asset, count: count);
  } finally {
    await staging.delete(recursive: true);
  }
}

Future<void> main(List<String> args) async {
  const flags = ['--index', '--library', '--output-dir'];
  final options = {
    for (var i = 0; i + 1 < args.length; i += 2) args[i]: args[i + 1],
  };
  if (args.length != 6 || !flags.every(options.containsKey)) {
    stderr.writeln(
      'Usage: dart run lib/data/discovery/imdb_prepare.dart --index <imdb.sqlite> '
      '--library <zauxoflix.sqlite> --output-dir <directory>',
    );
    exitCode = 64;
    return;
  }
  useSystemSqlite();
  final result = await prepare(
    File(options['--index']!),
    File(options['--library']!),
    Directory(options['--output-dir']!),
  );
  stdout.writeln(
    '${result.count} IMDb titles. ${result.asset.uri.pathSegments.last} '
    '(${result.asset.lengthSync()} bytes).',
  );
}
