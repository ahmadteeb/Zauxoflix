import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:zauxoflix/data/discovery/imdb_import.dart'
    show buildIndex, datasets;
import 'package:zauxoflix/data/discovery/imdb_prepare.dart' show prepare;

void main() {
  late Directory root;
  setUp(() => root = Directory.systemTemp.createTempSync('imdb-test-'));
  tearDown(() => root.deleteSync(recursive: true));

  void create(File file, String sql) {
    final db = sqlite3.open(file.path);
    db.execute(sql);
    db.dispose();
  }

  List<List<Object?>> query(File file, String sql) {
    final db = sqlite3.open(file.path, mode: OpenMode.readOnly);
    try {
      return db.select(sql).rows;
    } finally {
      db.dispose();
    }
  }

  test('device asset contains only selected IMDb metadata', () async {
    final full = File('${root.path}/full.sqlite');
    create(full, '''
      CREATE TABLE titles(id INTEGER PRIMARY KEY, title TEXT, original TEXT, kind TEXT, year INTEGER, end_year INTEGER, minutes INTEGER, genres TEXT);
      CREATE TABLE ratings(id INTEGER PRIMARY KEY, score REAL, votes INTEGER);
      CREATE TABLE cast_members(title_id INTEGER, position INTEGER, person_id INTEGER, characters TEXT, PRIMARY KEY(title_id,position));
      CREATE TABLE people(id INTEGER PRIMARY KEY, name TEXT, birth INTEGER, death INTEGER, professions TEXT, known_for TEXT);
      INSERT INTO titles VALUES(1,'A film',NULL,'movie',2022,NULL,105,'Comedy');
      INSERT INTO titles VALUES(2,'A film',NULL,'tvSeries',2022,NULL,NULL,'Drama');
      INSERT INTO titles VALUES(3,'A show',NULL,'tvSeries',2017,NULL,NULL,'Drama');
      INSERT INTO titles VALUES(4,'Missing',NULL,'movie',2022,NULL,101,NULL);
      INSERT INTO titles VALUES(5,'Cached',NULL,'movie',2001,NULL,90,NULL);
      INSERT INTO ratings VALUES(1,7.2,12345);
      INSERT INTO cast_members VALUES(1,1,8,NULL),(3,1,8,NULL),(4,1,9,NULL);
      INSERT INTO people VALUES(8,'Selected actor',NULL,NULL,'actor',NULL),(9,'Other actor',NULL,NULL,'actor',NULL);
      PRAGMA user_version=1;
    ''');
    final library = File('${root.path}/catalog.sqlite');
    create(library, '''
      CREATE TABLE movies(source_id,stream_id,name,release_year,external_id);
      CREATE TABLE series_items(source_id,series_id,name,release_year,external_id);
      CREATE TABLE discovery_entries(source_id,kind,item_id,fingerprint,payload);
      CREATE TABLE sources(secret);
      INSERT INTO sources VALUES('private-source-test');
      INSERT INTO movies VALUES(6,18,'EN | A film 2022',NULL,NULL);
      INSERT INTO movies VALUES(6,19,'Unlabelled',NULL,NULL);
      INSERT INTO series_items VALUES(6,22,'Local name',NULL,'tt0000003');
      INSERT INTO discovery_entries VALUES(6,'vod',19,'["Unlabelled",null,null]','{"title":{"ids":{"imdb":"tt0000005"}}}');
    ''');

    final out = Directory('${root.path}/assets');
    final result = await prepare(full, library, out);

    expect(result.count, 3);
    expect(out.listSync().single.path, endsWith('.sqlite.gz'));
    final unpacked = gzip.decode(result.asset.readAsBytesSync());
    final text = latin1.decode(unpacked);
    expect(text, isNot(contains('private-source-test')));
    expect(text, isNot(contains('Local name')));
    final device = File('${root.path}/device.sqlite')
      ..writeAsBytesSync(unpacked);
    expect(query(device, 'SELECT id FROM titles ORDER BY id'), [
      [1],
      [3],
      [5],
    ]);
    expect(query(device, 'SELECT name FROM people'), [
      ['Selected actor'],
    ]);
    expect(query(device, 'SELECT score FROM ratings'), [
      [7.2],
    ]);
    expect(
      query(device, "SELECT count(*) FROM sqlite_master WHERE type='table'"),
      [
        [4],
      ],
    );
  });

  test('anonymous credits, and a bad refresh keeps the old index', () async {
    const missing = r'\N';
    const data = {
      'title.basics': [
        [
          'tt0000012',
          'movie',
          missing,
          'Original title',
          '0',
          '2020',
          missing,
          '101',
          'Drama',
        ],
      ],
      'title.ratings': [
        ['tt0000012', '7.8', '10'],
      ],
      'title.principals': [
        ['tt0000012', '1', 'nm0000001', 'actor', missing, missing],
        ['tt0000012', '2', 'nm0000002', 'actress', missing, '["Lead"]'],
      ],
      'name.basics': [
        ['nm0000001', missing, missing, missing, missing, missing],
        ['nm0000002', 'Performer', missing, missing, 'actress', 'tt0000012'],
      ],
    };
    for (final MapEntry(key: name, value: records) in data.entries) {
      final lines = [
        datasets[name]!.replaceAll(' ', '\t'),
        for (final record in records) record.join('\t'),
      ];
      File(
        '${root.path}/$name.tsv.gz',
      ).writeAsBytesSync(gzip.encode(utf8.encode('${lines.join('\n')}\n')));
    }
    final output = File('${root.path}/imdb.sqlite');
    await buildIndex(root, output);
    expect(query(output, 'SELECT title,original,year,end_year FROM titles'), [
      ['Original title', null, 2020, null],
    ]);
    expect(
      query(
        output,
        'SELECT name,characters FROM cast_members JOIN people ON person_id=id',
      ),
      [
        ['Performer', '["Lead"]'],
      ],
    );

    final original = output.readAsBytesSync();
    final names = File('${root.path}/name.basics.tsv.gz');
    final bytes = names.readAsBytesSync();
    names.writeAsBytesSync(bytes.sublist(0, bytes.length - 12));
    await expectLater(buildIndex(root, output), throwsFormatException);
    names.deleteSync();
    await expectLater(
      buildIndex(root, output),
      throwsA(isA<FileSystemException>()),
    );
    expect(output.readAsBytesSync(), original);
    expect(root.listSync().where((e) => e.path.contains('import-')), isEmpty);
  });
}
