// Build a private title and cast index from IMDb's non-commercial TSV files.
//
// dart run lib/data/discovery/imdb_import.dart --output /path/to/imdb.sqlite [--datasets DIR]
import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'imdb_cli_sqlite.dart';

const datasets = {
  'title.basics':
      'tconst titleType primaryTitle originalTitle isAdult startYear endYear runtimeMinutes genres',
  'title.ratings': 'tconst averageRating numVotes',
  'title.principals': 'tconst ordering nconst category job characters',
  'name.basics':
      'nconst primaryName birthYear deathYear primaryProfession knownForTitles',
};
const _titleKinds = {
  'movie',
  'short',
  'tvMovie',
  'tvSeries',
  'tvMiniSeries',
  'tvShort',
  'tvSpecial',
  'video',
};
const _cast = {'actor', 'actress', 'self'};
const _missing = r'\N';

String? _field(String value) => value == _missing ? null : value;
int _id(String value) => int.parse(value.substring(2));

class _Sink<T> implements Sink<T> {
  _Sink(this.onData, [this.onClose]);
  final void Function(T) onData;
  final void Function()? onClose;
  @override
  void add(T data) => onData(data);
  @override
  void close() => onClose?.call();
}

/// Streams one dataset synchronously: the largest has tens of millions of rows.
void _rows(
  Directory directory,
  String dataset,
  void Function(List<String>) row,
) {
  stdout.writeln('Reading $dataset');
  final columns = datasets[dataset]!;
  final width = columns.split(' ').length;
  var header = true;
  var length = 0;
  final text = utf8.decoder.startChunkedConversion(
    const LineSplitter().startChunkedConversion(
      _Sink<String>((line) {
        final fields = line.split('\t');
        if (header) {
          header = false;
          if (fields.join(' ') != columns) {
            throw FormatException('Unexpected columns in $dataset');
          }
        } else if (fields.length != width) {
          throw FormatException('Malformed row in $dataset');
        } else {
          row(fields);
        }
      }),
    ),
  );
  final gunzip = gzip.decoder.startChunkedConversion(
    _Sink<List<int>>((data) {
      length += data.length;
      text.add(data);
    }, text.close),
  );
  final input = File('${directory.path}/$dataset.tsv.gz').openSync();
  try {
    while (true) {
      final chunk = input.readSync(1 << 16);
      if (chunk.isEmpty) break;
      gunzip.add(chunk);
    }
    gunzip.close();
    // Dart's decoder accepts a cut-off file; the gzip trailer holds the length.
    // shortcut: assumes one gzip member (IMDb's layout), revisit if that changes.
    final size = input.lengthSync();
    input.setPositionSync(size < 4 ? 0 : size - 4);
    final trailer = input.readSync(4);
    var expected = 0;
    for (final byte in trailer.reversed) {
      expected = expected << 8 | byte;
    }
    if (header || trailer.length < 4 || expected != length & 0xffffffff) {
      throw FormatException('Truncated $dataset');
    }
  } finally {
    input.closeSync();
  }
}

Future<void> buildIndex(Directory directory, File output) async {
  // Build beside the destination. A failed or interrupted refresh leaves the
  // previous complete index available to readers.
  await output.parent.create(recursive: true);
  final staging = await output.parent.createTemp('import-');
  try {
    final pending = File('${staging.path}/imdb.sqlite');
    final db = sqlite3.open(pending.path);
    try {
      db.execute('''
        PRAGMA journal_mode=OFF;
        PRAGMA synchronous=OFF;
        PRAGMA cache_size=-98304;
        CREATE TABLE titles(id INTEGER PRIMARY KEY, title TEXT NOT NULL,
            original TEXT, kind TEXT, year INTEGER, end_year INTEGER,
            minutes INTEGER, genres TEXT);
        CREATE TABLE ratings(id INTEGER PRIMARY KEY, score REAL, votes INTEGER);
        CREATE TABLE cast_members(title_id INTEGER, position INTEGER, person_id INTEGER,
            characters TEXT, PRIMARY KEY(title_id, position)) WITHOUT ROWID;
        CREATE TABLE people(id INTEGER PRIMARY KEY, name TEXT NOT NULL,
            birth INTEGER, death INTEGER, professions TEXT, known_for TEXT);
        BEGIN;
      ''');
      final titles = <int>{}, people = <int>{};
      void load(
        String dataset,
        String table,
        int columns,
        List<Object?>? Function(List<String>) map,
      ) {
        final insert = db.prepare(
          'INSERT INTO $table VALUES(${List.filled(columns, '?').join(',')})',
        );
        try {
          _rows(directory, dataset, (row) {
            final values = map(row);
            if (values != null) insert.execute(values);
          });
        } finally {
          insert.dispose();
        }
      }

      load('title.basics', 'titles', 8, (row) {
        final [tid, kind, name, original, _, year, end, minutes, genres] = row;
        if (!_titleKinds.contains(kind) ||
            (name == _missing && original == _missing)) {
          return null;
        }
        final key = _id(tid);
        titles.add(key);
        final label = _field(name) ?? original;
        return [
          key,
          label,
          original != label ? _field(original) : null,
          kind,
          _field(year),
          _field(end),
          _field(minutes),
          _field(genres),
        ];
      });
      load('title.ratings', 'ratings', 3, (row) {
        final key = _id(row[0]);
        return titles.contains(key)
            ? [key, double.parse(row[1]), int.parse(row[2])]
            : null;
      });
      load('title.principals', 'cast_members', 4, (row) {
        final [tid, order, pid, category, _, characters] = row;
        if (!_cast.contains(category)) return null;
        final key = _id(tid);
        if (!titles.contains(key)) return null;
        final person = _id(pid);
        people.add(person);
        return [key, int.parse(order), person, _field(characters)];
      });
      titles.clear();
      load('name.basics', 'people', 6, (row) {
        final [pid, name, birth, death, jobs, known] = row;
        if (name == _missing || name.isEmpty || !people.contains(_id(pid))) {
          return null;
        }
        return [
          _id(pid),
          name,
          _field(birth),
          _field(death),
          _field(jobs),
          _field(known),
        ];
      });
      db.execute('''
        CREATE INDEX cast_by_person ON cast_members(person_id, title_id);
        PRAGMA user_version=1;
        COMMIT;
      ''');
    } finally {
      db.dispose();
    }
    await pending.rename(output.path);
  } finally {
    await staging.delete(recursive: true);
  }
}

Future<void> _download(Directory directory) async {
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 60)
    ..autoUncompress = false;
  try {
    for (final name in datasets.keys) {
      final filename = '$name.tsv.gz';
      stdout.writeln('Downloading $filename');
      final url = Uri.https('datasets.imdbws.com', '/$filename');
      final response = await (await client.getUrl(url)).close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}', uri: url);
      }
      await response
          .timeout(const Duration(seconds: 60))
          .pipe(File('${directory.path}/$filename').openWrite());
    }
  } finally {
    client.close(force: true);
  }
}

Future<void> main(List<String> args) async {
  String? output, source;
  for (var i = 0; i < args.length; i += 2) {
    final value = i + 1 < args.length ? args[i + 1] : null;
    if (args[i] == '--output') {
      output = value;
    } else if (args[i] == '--datasets') {
      source = value;
    } else {
      output = null;
      break;
    }
    if (value == null) output = null;
  }
  if (output == null) {
    stderr.writeln(
      'Usage: dart run lib/data/discovery/imdb_import.dart --output <imdb.sqlite> '
      '[--datasets <directory with the four .tsv.gz files>]',
    );
    exitCode = 64;
    return;
  }
  useSystemSqlite();
  if (source != null) {
    await buildIndex(Directory(source), File(output));
    return;
  }
  final temp = await Directory.systemTemp.createTemp('imdb-');
  try {
    await _download(temp);
    await buildIndex(temp, File(output));
  } finally {
    await temp.delete(recursive: true);
  }
}
