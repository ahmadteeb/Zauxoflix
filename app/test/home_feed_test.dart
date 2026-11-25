import 'dart:async';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zauxoflix/data/providers.dart';
import 'package:zauxoflix/data/discovery/home_feed.dart';
import 'package:zauxoflix/data/discovery/discovery_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/discovery/home_catalog.dart';
import 'package:zauxoflix/data/discovery/home_ranking.dart';
import 'package:zauxoflix/data/discovery/trakt_client.dart';

void main() {
  const movie = CatalogKind.vod, series = CatalogKind.series;
  final now = DateTime.utc(2026, 6);
  test(
    'large offline library ranks off the UI isolate and refreshes after a save',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          discoveryClientProvider.overrideWithValue(null),
          homeIndexPathProvider.overrideWith((_) async => null),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      final source = await db.insertSource(
        SourcesCompanion.insert(
          name: 'Local library',
          serverUrl: '',
          username: '',
          password: '',
        ),
      );
      await db.replaceMovies(source, [
        for (var i = 0; i < 805; i++)
          MoviesCompanion.insert(
            sourceId: source,
            streamId: i,
            name: 'Title $i',
          ),
      ]);
      final p = homeFeedProvider(source);
      container.listen(p, (_, _) {});
      container.listen(homeDisplayFeedProvider(source), (_, _) {});
      final first = (await container.read(p.future)).movies.first;
      final updated = Completer<void>();
      container.listen(p, (_, next) {
        final feed = next.asData?.value;
        if (feed != null &&
            !updated.isCompleted &&
            feed.movies.every((m) => m.id != first.id)) {
          updated.complete();
        }
      });
      await db.addFavorite(
        sourceId: source,
        kind: movie,
        itemId: first.id!,
        name: first.title,
      );
      await updated.future;
      expect(
        container.read(p).requireValue.movies.any((m) => m.id == first.id),
        isFalse,
      );
    },
  );
  HomeActivity signal(
    LibraryWork work,
    HomeSignal signal, {
    int days = 0,
    double progress = 1,
  }) => (
    key: work.key,
    signal: signal,
    stamp: now.subtract(Duration(days: days)).millisecondsSinceEpoch ~/ 1000,
    progress: progress,
  );
  LibraryWork work(
    int id, {
    CatalogKind kind = movie,
    String lang = 'tr',
    int year = 1980,
    String genre = 'drama',
    String? name,
  }) {
    return LibraryWork(
      kind,
      id,
      name ?? 'Title $id',
      year: year,
      cached: TraktTitle(
        id,
        'Title $id',
        year,
        null,
        null,
        language: lang,
        genres: [genre],
      ),
    );
  }

  test(
    'saved, completed and in-progress preferences transfer across formats and languages',
    () {
      for (final s in HomeSignal.values) {
        final seed = work(1),
            same = work(2, kind: series),
            wrongLanguage = work(3, lang: 'en', kind: series),
            wrongEra = work(4, year: 2025, kind: series);
        final feed = rankHome(
          [seed, work(5), same, wrongLanguage, wrongEra],
          [signal(seed, s)],
          {},
          now,
        );
        expect(feed.series.first.id, 2);
        expect(feed.movies.map((p) => p.id), [5]);
        expect(feed.series.first.reason, contains(seed.name));
      }
    },
  );
  test(
    'recent completion outweighs a brief start and older activity fades',
    () {
      final a = work(1), b = work(2, lang: 'fr', year: 2025, genre: 'comedy');
      final similarA = work(3),
          similarB = work(4, lang: 'fr', year: 2025, genre: 'comedy');
      for (final old in [false, true]) {
        final history = [
          signal(
            a,
            old ? HomeSignal.watched : HomeSignal.watching,
            days: old ? 900 : 0,
            progress: .05,
          ),
          signal(b, HomeSignal.watched),
        ];
        expect(
          rankHome(
            [a, b, similarA, similarB],
            history,
            {},
            now,
          ).movies.first.id,
          4,
        );
      }
    },
  );
  test(
    'vote confidence, future releases, duplicate editions and cold start',
    () {
      final high = work(1),
          few = work(2),
          future = work(3, year: 2027),
          duplicate = work(4);
      high.imdb = (
        id: 'tt0000001',
        score: 9.0,
        votes: 90000,
        genres: ['drama'],
        year: 1980,
      );
      few.imdb = (
        id: 'tt0000002',
        score: 10.0,
        votes: 3,
        genres: ['drama'],
        year: 1980,
      );
      duplicate.imdb = high.imdb;
      final library = [high, few, future, duplicate, work(5, kind: series)];
      final feed = rankHome(library, [], {}, now);
      expect(feed.movies.map((p) => p.id), [1, 2]);
      expect(feed.featured.first.highlyRated, isTrue);
      expect(feed.featured.any((p) => p.work.kind == series), isTrue);
      final seen = rankHome(library, [signal(high, HomeSignal.saved)], {}, now);
      expect(seen.movies.map((p) => p.id), [2]);
    },
  );
  test(
    'related credits require matching kind and year and respect exact air date',
    () {
      final seed = work(10),
          other = LibraryWork(movie, 2, 'Second', year: 2026),
          remake = LibraryWork(movie, 3, 'Second', year: 2023);
      final upcoming = LibraryWork(movie, 4, 'Third', year: 2026);
      const second = TraktTitle(
        44,
        'Second',
        2026,
        'tt0000044',
        null,
        language: 'fr',
        releaseDate: '2026-02-10',
      );
      const third = TraktTitle(
        45,
        'Third',
        2026,
        'tt0000045',
        null,
        releaseDate: '2026-12-10',
      );
      final result = rankHome(
        [seed, other, remake, upcoming],
        [signal(seed, HomeSignal.saved)],
        {
          seed.key: TitleDiscovery(seed.cached!, null, {}, [second, third]),
        },
        now,
      );
      expect(result.movies.map((p) => p.id), [2, 3]);
      expect(result.movies.first.reason, contains(seed.name));
    },
  );
  test(
    'explicit language categories work offline and bilingual titles alone do not imply audio language',
    () {
      final seed = LibraryWork(movie, 1, 'Saved', category: 'Turkish | تركي');
      final same = LibraryWork(
        series,
        2,
        'Other',
        category: 'Turkish classics',
      );
      final caption = LibraryWork(
        series,
        3,
        'Translated - مترجم',
        category: 'Subtitle Turkish Series',
      );
      final result = rankHome(
        [seed, same, caption],
        [signal(seed, HomeSignal.saved)],
        {},
        now,
      );
      expect(result.series.first.id, 2);
      expect(result.series.last.reason, 'From your library');
    },
  );
  test('IMDb match requires unambiguous format and year or an exact ID', () {
    final dir = Directory.systemTemp.createTempSync();
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = '${dir.path}/imdb.sqlite', db = sqlite3.open(path);
    db.execute(
      'CREATE TABLE titles(id INTEGER PRIMARY KEY,title,original,year,kind,genres); CREATE TABLE ratings(id INTEGER PRIMARY KEY,score,votes); PRAGMA user_version=1;',
    );
    for (final r in [
      [1, 'Red Roses', 'Kızıl Goncalar', 2023, 'tvSeries', 'Drama'],
      [2, 'Shared', null, 2001, 'movie', 'Mystery'],
      [3, 'Shared', null, 2001, 'movie', 'Drama'],
    ]) {
      db.execute('INSERT INTO titles VALUES(?,?,?,?,?,?)', r);
      db.execute('INSERT INTO ratings VALUES(?,8.1,12000)', [r.first]);
    }
    db.dispose();
    final a = LibraryWork(
          series,
          1,
          'Kızıl Goncalar - البراعم الحمراء',
          year: 2023,
        ),
        b = LibraryWork(movie, 2, 'Shared 2001'),
        c = LibraryWork(movie, 3, 'Provider label', external: 'tt0000002'),
        d = LibraryWork(movie, 4, 'Red Roses', year: 2023);
    readHomeRatings(path, [a, b, c, d]);
    expect(a.imdb?.id, 'tt0000001');
    expect(b.imdb, isNull);
    expect(c.imdb?.score, 8.1);
    expect(d.imdb, isNull);
  });
}
