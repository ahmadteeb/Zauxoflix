import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../core/app_platform.dart';
import '../db/app_database.dart' show CatalogKind, configureWebOsSqlite;
import 'home_catalog.dart';
import 'imdb_asset.dart';
import 'title_identity.dart';
import 'trakt_client.dart' show ActingCredit;

typedef ImdbPerson = ({
  String id,
  String name,
  List<String> characters,
  int? birth,
  int? death,
  List<String> professions,
  List<String> knownFor,
});

typedef ImdbTitle = ({
  String title,
  String? original,
  String kind,
  int? year,
  int? endYear,
  int? minutes,
  List<String> genres,
  double? rating,
  int? votes,
  List<ImdbPerson> cast,
});

final imdbTitleProvider = FutureProvider.autoDispose.family<ImdbTitle?, String>(
  (ref, imdbId) async {
    if (validImdb(imdbId) == null) return null;
    final path = await ref.watch(imdbIndexPathProvider.future);
    if (path == null) return null;
    return Isolate.run(() => readImdbTitle(path, imdbId));
  },
);

final imdbActingCreditsProvider = FutureProvider.autoDispose
    .family<List<ActingCredit>?, String>((ref, personId) async {
      final path = await ref.watch(imdbIndexPathProvider.future);
      if (path == null) return null;
      return Isolate.run(() => readActingCredits(path, personId));
    });

final localImdbIdProvider = FutureProvider.autoDispose
    .family<String?, ({CatalogKind kind, String name, int? year})>((
      ref,
      key,
    ) async {
      final path = await ref.watch(imdbIndexPathProvider.future);
      if (path == null) return null;
      return Isolate.run(
        () => matchLocalImdbId(path, key.kind, key.name, key.year),
      );
    });

String? matchLocalImdbId(
  String path,
  CatalogKind kind,
  String name,
  int? year,
) {
  final work = LibraryWork(kind, 0, name, year: year);
  if (work.year == null || work.names.isEmpty) return null;
  if (isWebOsPlatform) configureWebOsSqlite();
  final db = sqlite3.open(path, mode: OpenMode.readOnly);
  try {
    if (db.userVersion != 1) return null;
    final formats = kind == CatalogKind.series
        ? "'tvSeries','tvMiniSeries'"
        : "'movie','tvMovie','video'";
    final slots = List.filled(work.names.length, '?').join(',');
    final rows = db.select(
      '''SELECT id FROM titles WHERE year=? AND kind IN ($formats)
      AND (lower(title) IN ($slots) OR lower(original) IN ($slots)) LIMIT 2''',
      [work.year, ...work.names, ...work.names],
    );
    return rows.length == 1
        ? 'tt${rows.single['id'].toString().padLeft(7, '0')}'
        : null;
  } finally {
    db.dispose();
  }
}

List<ActingCredit>? readActingCredits(String path, String personId) {
  if (!RegExp(r'^nm[0-9]{7,12}$').hasMatch(personId) ||
      !File(path).existsSync()) {
    return null;
  }
  if (isWebOsPlatform) configureWebOsSqlite();
  final db = sqlite3.open(path, mode: OpenMode.readOnly);
  try {
    if (db.userVersion != 1) return null;
    return [
      for (final row in db.select(
        '''SELECT DISTINCT t.id,t.title,t.original,t.year,t.kind
        FROM cast_members c JOIN titles t ON t.id=c.title_id WHERE c.person_id=?''',
        [int.parse(personId.substring(2))],
      ))
        ActingCredit(
          row['kind'] == 'tvSeries' || row['kind'] == 'tvMiniSeries'
              ? CatalogKind.series
              : CatalogKind.vod,
          row['title'] as String,
          row['year'] as int?,
          original: row['original'] as String?,
          imdb: 'tt${row['id'].toString().padLeft(7, '0')}',
        ),
    ];
  } finally {
    db.dispose();
  }
}

List<String> _list(String? input) =>
    input == null || input.isEmpty ? const [] : input.split(',');

List<String> _characters(String? raw) {
  if (raw == null) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) return decoded.whereType<String>().toList();
  } on FormatException {
    // A malformed role still has a valid performer and title credit.
  }
  return const [];
}

ImdbTitle? readImdbTitle(String path, String imdbId) {
  final id = validImdb(imdbId);
  if (id == null || !File(path).existsSync()) return null;
  if (isWebOsPlatform) configureWebOsSqlite();
  final db = sqlite3.open(path, mode: OpenMode.readOnly);
  try {
    if (db.userVersion != 1) return null;
    final key = int.parse(id.substring(2));
    final title = db
        .select(
          '''
      SELECT t.*, r.score, r.votes FROM titles t
      LEFT JOIN ratings r ON r.id=t.id WHERE t.id=?
    ''',
          [key],
        )
        .firstOrNull;
    if (title == null) return null;
    final cast = <ImdbPerson>[];
    for (final row in db.select(
      '''
      SELECT p.*, c.characters FROM cast_members c
      JOIN people p ON p.id=c.person_id WHERE c.title_id=? ORDER BY c.position
    ''',
      [key],
    )) {
      final known = <String>[];
      for (final ref in _list(row['known_for'] as String?)) {
        if (validImdb(ref) == null) continue;
        final work = db.select('SELECT title,year FROM titles WHERE id=?', [
          int.parse(ref.substring(2)),
        ]).firstOrNull;
        if (work != null) {
          known.add(
            [
              work['title'],
              if (work['year'] != null) '(${work['year']})',
            ].join(' '),
          );
        }
      }
      cast.add((
        id: 'nm${row['id'].toString().padLeft(7, '0')}',
        name: row['name'] as String,
        characters: _characters(row['characters'] as String?),
        birth: row['birth'] as int?,
        death: row['death'] as int?,
        professions: _list(
          row['professions'] as String?,
        ).map((s) => s.replaceAll('_', ' ')).toList(),
        knownFor: known,
      ));
    }
    return (
      title: title['title'] as String,
      original: title['original'] as String?,
      kind: switch (title['kind']) {
        'tvSeries' => 'TV series',
        'tvMiniSeries' => 'Miniseries',
        'tvShort' => 'TV short',
        'tvMovie' => 'TV movie',
        'tvSpecial' => 'TV special',
        'short' => 'Short film',
        'video' => 'Video',
        _ => 'Movie',
      },
      year: title['year'] as int?,
      endYear: title['end_year'] as int?,
      minutes: title['minutes'] as int?,
      genres: _list(title['genres'] as String?),
      rating: (title['score'] as num?)?.toDouble(),
      votes: title['votes'] as int?,
      cast: cast,
    );
  } finally {
    db.dispose();
  }
}
