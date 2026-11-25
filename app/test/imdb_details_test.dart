import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:zauxoflix/core/theme/app_theme.dart';
import 'package:zauxoflix/core/widgets/app_image.dart';
import 'package:zauxoflix/features/details/imdb_details.dart';
import 'package:zauxoflix/features/details/cast_gallery.dart';
import 'package:zauxoflix/core/widgets/external_link.dart';
import 'package:zauxoflix/data/db/app_database.dart' show CatalogKind;
import 'package:zauxoflix/data/discovery/discovery_repository.dart';
import 'package:zauxoflix/data/discovery/actor_library.dart';
import 'package:zauxoflix/data/discovery/imdb_index.dart';
import 'package:zauxoflix/data/discovery/imdb_asset.dart';
import 'package:zauxoflix/data/discovery/trakt_client.dart';
import 'package:zauxoflix/features/details/details_widgets.dart';

void main() {
  late Directory directory;
  late String path;
  const id = 'tt0000012';
  const CatalogTitle key = (
    source: 1,
    kind: CatalogKind.vod,
    id: 1,
    name: 'Library title',
    year: null,
    external: id,
  );

  setUpAll(() {
    directory = Directory.systemTemp.createTempSync('imdb_details_');
    path = '${directory.path}/imdb.sqlite';
    final db = sqlite3.open(path);
    db.execute('''
      CREATE TABLE titles(id INTEGER PRIMARY KEY,title TEXT,original TEXT,kind TEXT,year INTEGER,end_year INTEGER,minutes INTEGER,genres TEXT);
      CREATE TABLE ratings(id INTEGER PRIMARY KEY,score REAL,votes INTEGER);
      CREATE TABLE people(id INTEGER PRIMARY KEY,name TEXT,birth INTEGER,death INTEGER,professions TEXT,known_for TEXT);
      CREATE TABLE cast_members(title_id INTEGER,position INTEGER,person_id INTEGER,characters TEXT);
      INSERT INTO titles VALUES(12,'Matched film','Original name','movie',2020,NULL,105,'Drama,Comedy');
      INSERT INTO titles VALUES(22,'Earlier work',NULL,'short',2001,NULL,NULL,NULL);
      INSERT INTO ratings VALUES(12,7.8,1234);
      PRAGMA user_version=1;
    ''');
    for (var i = 1; i <= 7; i++) {
      db.execute('INSERT INTO people VALUES(?,?,?,?,?,?)', [
        i,
        'Performer $i',
        i == 1 ? 1970 : null,
        null,
        'actor,stunt_department',
        'tt0000022,tt9999999',
      ]);
      db.execute('INSERT INTO cast_members VALUES(?,?,?,?)', [
        12,
        i,
        i,
        switch (i) {
          1 => '["First role","Second role"]',
          7 => 'Unknown',
          _ => null,
        },
      ]);
    }
    db.dispose();
  });
  tearDownAll(() => directory.deleteSync(recursive: true));

  test(
    'device index installs once and retains the prior generation on an interrupted refresh',
    () async {
      final destination = directory.createTempSync('device-');
      final original = gzip.encode(File(path).readAsBytesSync());
      final asset = 'assets/private_imdb/imdb-${'a' * 64}.sqlite.gz';
      var loads = 0;
      Future<ByteData> load(String name) async {
        loads++;
        return ByteData.sublistView(Uint8List.fromList(original));
      }

      final installed = await installDeviceImdb(destination, asset, load);
      expect(readImdbTitle(installed, id)!.rating, 7.8);
      expect(await installDeviceImdb(destination, asset, load), installed);
      expect(loads, 1);
      final update = 'assets/private_imdb/imdb-${'b' * 64}.sqlite.gz';
      await expectLater(
        installDeviceImdb(destination, update, (_) async => ByteData(16)),
        throwsA(anything),
      );
      expect(File(installed).existsSync(), isTrue);
      final refreshed = await installDeviceImdb(destination, update, load);
      expect(readImdbTitle(refreshed, id)!.cast, hasLength(7));
      expect(File(installed).existsSync(), isFalse);
    },
  );

  test('offline title matching requires an unambiguous year and media kind', () {
    expect(
      matchLocalImdbId(path, CatalogKind.vod, 'Matched film 2020', null),
      id,
    );
    expect(matchLocalImdbId(path, CatalogKind.vod, 'Original name', 2020), id);
    expect(
      matchLocalImdbId(path, CatalogKind.series, 'Matched film 2020', null),
      isNull,
    );
    expect(
      matchLocalImdbId(path, CatalogKind.vod, 'Matched film', null),
      isNull,
    );
    final duplicate = File(path).copySync('${directory.path}/ambiguous.sqlite');
    final data = sqlite3.open(duplicate.path);
    data.execute(
      "INSERT INTO titles VALUES(34,'Matched film',NULL,'movie',2020,NULL,90,NULL)",
    );
    data.dispose();
    expect(
      matchLocalImdbId(
        duplicate.path,
        CatalogKind.vod,
        'Matched film 2020',
        null,
      ),
      isNull,
    );
  });

  test(
    'index resolves exact title IDs, billing order and linked performer facts',
    () {
      final title = readImdbTitle(path, id)!;
      expect(title.rating, 7.8);
      expect(title.cast.map((p) => p.name).first, 'Performer 1');
      final actor = title.cast.first;
      expect(actor.id, 'nm0000001');
      expect(actor.characters, ['First role', 'Second role']);
      expect(actor.knownFor, ['Earlier work (2001)']);
      expect(title.cast.last.birth, isNull);
      expect(title.cast.last.characters, isEmpty);
      expect(readImdbTitle(path, 'tt0000022')!.cast, isEmpty);
      expect(readImdbTitle(path, 'tt9999999'), isNull);
      expect(readImdbTitle(path, 'nm0000012'), isNull);
      expect(readImdbTitle('${directory.path}/missing.sqlite', id), isNull);
    },
  );

  testWidgets(
    'a series without a local index shows matched Trakt cast and photos',
    (tester) async {
      const titleId = 'tt0000022';
      const key = (
        source: 1,
        kind: CatalogKind.series,
        id: 2,
        name: 'Series',
        year: 2020,
        external: titleId,
      );
      const photo = 'https://media.trakt.tv/people/1/headshot.webp';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            titleDiscoveryProvider(key).overrideWith((_) async => null),
            relatedTitlesProvider(key).overrideWith((_) async => []),
            actorLibraryProvider((
              personId: "nm0000001",
              origin: (
                source: 1,
                kind: CatalogKind.series,
                id: 2,
                external: titleId,
              ),
            )).overrideWith(
              (_) =>
                  Stream.value((items: [], checking: false, incomplete: false)),
            ),
            imdbTitleProvider(titleId).overrideWith((_) async => null),
            castCreditsProvider((CatalogKind.series, titleId)).overrideWith(
              (_) async => [
                (
                  id: 'nm0000001',
                  name: 'First cast member',
                  roles: ['Lead'],
                  photo: photo,
                ),
                (
                  id: 'nm0000002',
                  name: 'Second cast member',
                  roles: ['Friend'],
                  photo: null,
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DetailsScaffold(
                title: 'Series',
                onPlay: null,
                discoveryKey: key,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Second cast member'), findsOneWidget);
      expect(tester.widget<AppImage>(find.byType(AppImage)).url, photo);
      await tester.tap(find.text('First cast member'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('As Lead'), findsOneWidget);
      expect(find.byType(AppImage), findsNWidgets(2));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'missing, loading and failed headshots share the portrait layout',
    (tester) async {
      final cast = <ImdbPerson>[
        (
          id: 'nm0000001',
          name: 'Mina Demirtaş',
          characters: ['Selin'],
          birth: null,
          death: null,
          professions: [],
          knownFor: [],
        ),
        (
          id: 'nm0000002',
          name: 'Çağdaş Onur Öztürk',
          characters: ['Sinan'],
          birth: null,
          death: null,
          professions: [],
          knownFor: [],
        ),
      ];
      const url = 'https://media.trakt.tv/example/offline-headshot.webp';
      final response = Completer<ImageInfo>();
      final provider = ResizeImage.resizeIfNeeded(
        512,
        null,
        const CachedNetworkImageProvider(url),
      );
      final imageKey = await provider.obtainKey(ImageConfiguration.empty);
      PaintingBinding.instance.imageCache.putIfAbsent(
        imageKey,
        () => OneFrameImageStreamCompleter(response.future),
      );
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: CastGallery(
                  title: 'Cast',
                  cast: cast,
                  photos: {cast.last.id: url},
                ),
              ),
            ),
          ),
        ),
      );
      final missing = find.widgetWithText(OutlinedButton, 'Mina Demirtaş');
      final loading = find.widgetWithText(OutlinedButton, 'Çağdaş Onur Öztürk');
      final bounds = tester.getRect(loading);
      expect(tester.getSize(missing), bounds.size);
      expect(bounds.height, greaterThan(180));
      expect(find.text('MD'), findsOneWidget);
      expect(find.text('ÇÖ'), findsOneWidget);
      response.completeError(StateError('Photo unavailable'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(tester.getRect(loading), bounds);
      expect(find.text('ÇÖ'), findsOneWidget);
      Focus.of(tester.element(find.text('Mina Demirtaş'))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('MD'),
        ),
        findsOneWidget,
      );
      expect(find.text('As Selin'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [390.0, 1280.0, 1920.0]) {
    testWidgets(
      'open and close an IMDb performer from title Details at $width',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final details = readImdbTitle(path, id)!;
        Uri? opened;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              titleDiscoveryProvider(key).overrideWith((_) async => null),
              relatedTitlesProvider(key).overrideWith((_) async => []),
              actorLibraryProvider((
                personId: "nm0000001",
                origin: (source: 1, kind: CatalogKind.vod, id: 1, external: id),
              )).overrideWith(
                (_) => Stream.value((
                  items: [],
                  checking: false,
                  incomplete: false,
                )),
              ),
              imdbTitleProvider(id).overrideWith((_) async => details),
              externalLinkLauncherProvider.overrideWithValue((uri) async {
                opened = uri;
                return true;
              }),
            ],
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const Scaffold(
                body: DetailsScaffold(
                  title: 'Library title',
                  onPlay: null,
                  discoveryKey: key,
                  plot: 'Provider plot',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final imdbLink = find.descendant(
          of: find.byType(ImdbDetails),
          matching: find.text('View on IMDb'),
        );
        expect(imdbLink, findsOneWidget);
        await tester.ensureVisible(imdbLink);
        await tester.tap(imdbLink);
        expect(opened.toString(), 'https://www.imdb.com/title/$id/');
        expect(find.text('Matched film'), findsOneWidget);
        expect(find.text('7.8/10'), findsOneWidget);
        final all = find.text('Show all 7 cast members');
        await tester.ensureVisible(all);
        await tester.tap(all);
        await tester.pumpAndSettle();
        expect(find.text('Performer 7'), findsOneWidget);
        final first = find.text('Performer 1');
        await tester.ensureVisible(first);
        await tester.tap(first);
        await tester.pumpAndSettle();
        expect(find.text('Born 1970'), findsOneWidget);
        expect(find.text('Earlier work (2001)'), findsOneWidget);
        await tester.tap(find.text('View profile on IMDb'));
        expect(opened.toString(), 'https://www.imdb.com/name/nm0000001/');
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('Known for'), findsNothing);
        expect(find.text('IMDb details'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
