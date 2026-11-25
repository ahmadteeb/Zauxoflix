import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zauxoflix/core/responsive/form_factor.dart';
import 'package:zauxoflix/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/providers.dart';
import 'package:zauxoflix/data/discovery/chart_sources.dart';
import 'package:zauxoflix/data/discovery/discovery_repository.dart';
import 'package:zauxoflix/data/discovery/daily_cache.dart';
import 'package:zauxoflix/data/discovery/home_catalog.dart';
import 'package:zauxoflix/data/discovery/home_feed.dart';
import 'package:zauxoflix/data/discovery/home_ranking.dart';
import 'package:zauxoflix/data/discovery/home_snapshot.dart';
import 'package:zauxoflix/data/discovery/top_charts.dart';
import 'package:zauxoflix/data/discovery/trakt_client.dart';
import 'package:zauxoflix/features/home/widgets/top_charts_section.dart';
import 'package:zauxoflix/features/home/widgets/home_spotlight.dart';
import 'package:zauxoflix/features/home/widgets/spotlight_rotation.dart';
import 'package:zauxoflix/features/home/widgets/hero_banner.dart';
import 'package:zauxoflix/core/models/media_item.dart';

class TestCharts extends ChartSources {
  TestCharts() : super(Dio(), null);
  int reads = 0;
  bool offline = false;
  List<Json> items(String label) => [
    for (var i = 1; i <= 10; i++)
      {'name': '$label $i', 'url': 'https://tv.apple.com/jo/movie/$i'},
  ];
  @override
  Future<Json> dailyRegion(String region) async {
    reads++;
    if (offline) throw StateError('offline');
    return {'vod': items('Jordan film'), 'series': items('Jordan show')};
  }

  @override
  Future<Json> dailyGlobal(CatalogKind kind) async {
    reads++;
    return {'items': items('World ${kind.name}')};
  }

  @override
  Future<Json> monthly(
    String day,
    Snapshot? old, {
    required bool global,
  }) async {
    reads++;
    final group = global ? 'world' : 'JO';
    return {
      'charts': {
        '$group/vod': items('Monthly movies'),
        '$group/series': items('Monthly series'),
      },
      'through': {'$group/vod': day, '$group/series': day},
      'month': day.substring(0, 7),
    };
  }
}

void main() {
  test(
    'day cache coalesces concurrent loads, survives restart, rejects a late older result and retries offline',
    () async {
      final dir = Directory.systemTemp.createTempSync(),
          file = File('${dir.path}/db.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      var cache = DailyCache(db);
      const key = (source: 0, slot: 'test');
      int n = 0;
      Future<Json> build(Snapshot? _) async => {'n': ++n};
      final today = '2026-11-23';
      await Future.wait([
        for (var i = 0; i < 5; i++) cache.get(key, today, build),
      ]);
      expect(n, 1);
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(file));
      cache = DailyCache(db);
      try {
        expect((await cache.get(key, today, build)).data['n'], 1);
        final started = Completer<void>(), slow = Completer<Json>();
        final late = cache.get(key, '2026-11-24', (_) async {
          started.complete();
          return slow.future;
        });
        await started.future;
        final fresh = await cache.get(key, '2026-11-25', build);
        slow.complete({'n': 10});
        await late;
        expect((await cache.read(key))?.day, fresh.day);
        int errors = 0;
        Future<Json> fail(Snapshot? _) async {
          errors++;
          throw StateError('offline');
        }

        for (var i = 0; i < 2; i++) {
          expect(
            (await cache.get(key, '2026-11-26', fail, allowStale: true)).day,
            fresh.day,
          );
        }
        expect(errors, 1);
        cache.retry(key, '2026-11-26');
        expect((await cache.get(key, '2026-11-26', build)).day, '2026-11-26');
      } finally {
        await db.close();
        dir.deleteSync(recursive: true);
      }
    },
  );
  test('a new account cannot reuse an in-flight personal ranking', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final source = await db.insertSource(
      SourcesCompanion.insert(
        name: 'Library',
        serverUrl: '',
        username: '',
        password: '',
      ),
    );
    final day = '2026-11-23', id = (source: source, slot: 'home.v1');
    final cache = DailyCache(db),
        started = Completer<void>(),
        old = Completer<Json>();
    final pending = cache.get(id, day, (_) {
      started.complete();
      return old.future;
    });
    await started.future;
    await db.clearSyncedData();
    await cache.get(id, day, (_) async => {'profile': 'new'});
    final rejected = expectLater(pending, throwsStateError);
    old.complete({'profile': 'old'});
    await rejected;
    expect((await cache.read(id))?.data['profile'], 'new');
  });
  test(
    'calendar month uses only published weeks in scope and one best regional rank per series per week',
    () async {
      final lines = [
        'country_iso2\tweek\tcategory\tweekly_rank\tshow_title',
        'JO\t2026-10-25\tTV\t1\tOld',
        'JO\t2026-11-01\tTV\t3\tA',
        'JO\t2026-11-01\tTV\t4\tA',
        'JO\t2026-11-01\tTV\t1\tB',
        'JO\t2026-11-08\tTV\t2\tB',
        'US\t2026-11-08\tTV\t1\tUS title',
        'JO\t2026-11-29\tTV\t1\tLater',
      ];
      final month = await netflixMonth(
        Stream.fromIterable(lines),
        '2026-11-23',
        global: false,
      );
      final charts = month['charts'] as Json;
      expect((charts['JO/series'] as List).cast<Json>().map((r) => r['name']), [
        'B',
        'A',
      ]);
      expect((month['through'] as Json)['JO/series'], '2026-11-08');
      final views = await netflixMonth(
        Stream.fromIterable([
          'week\tcategory\tweekly_rank\tshow_title\tweekly_views',
          '2026-11-08\tFilms (English)\t1\tOne\t100',
          '2026-11-01\tFilms (Non-English)\t4\tTwo\t80',
          '2026-11-08\tFilms (Non-English)\t3\tTwo\t80',
        ]),
        '2026-11-23',
        global: true,
      );
      expect(
        (((views['charts'] as Json)['world/vod'] as List).first
            as Json)['name'],
        'Two',
      );
    },
  );
  test(
    'regional day parser requires a real storefront chart and preserves rank',
    () {
      Json shelf(String key, String name) => {
        r'$type': 'chart',
        'id': 'uts.col.Charts$key.tvs.sbd.4000',
        'items': [
          {
            'contextAction': {
              'title': name,
              'url': 'https://tv.apple.com/jo/show/a',
            },
            'artwork': {
              'template': 'https://is1-ssl.mzstatic.com/a/{w}x{h}.{f}',
            },
          },
        ],
      };
      final page =
          '<script id="serialized-server-data" type="application/json">${jsonEncode([shelf('Shows', 'Series'), shelf('Movies', 'Film')])}</script>';
      expect(
        ((appleCharts(page, 'JO')['series'] as List).single as Json)['name'],
        'Series',
      );
      expect(() => appleCharts(page, 'US'), throwsFormatException);
    },
  );
  test(
    'daily hero stays relevant and gives previous picks a three-day cooldown when the pool allows',
    () {
      final works = [
        for (final k in [CatalogKind.vod, CatalogKind.series])
          for (int i = 0; i < 60; i++)
            LibraryWork(k, i, '${k.name} $i', year: 2020, category: 'Drama')
              ..imdb = (
                id: 'tt${(1000000 + i + (k == CatalogKind.series ? 100 : 0))}',
                score: 8.3,
                votes: 100000,
                genres: ['drama'],
                year: 2020,
              ),
      ];
      HomeFeed get(int day, Map<String, int> seen) => rankHome(
        works,
        [],
        {},
        DateTime(2026, 11, day),
        daySeed: day,
        recentFeatures: seen,
      );
      final first = get(23, {}),
          firstKeys = first.featured.map((p) => p.work.key).toSet();
      expect(get(23, {}).featured.map((p) => p.work.key).toSet(), firstKeys);
      final next = get(24, {
        for (final p in first.featured)
          '${p.work.kind.name}/${p.work.identity}': 23,
      });
      expect(
        next.featured.map((p) => p.work.key).toSet().intersection(firstKeys),
        isEmpty,
      );
      expect(next.featured.length, 6);
      expect(
        next.featured.any((p) => p.reason == 'Highly rated on IMDb'),
        isTrue,
      );
    },
  );
  test(
    'Home reuses its ranked feed across sessions until local midnight',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final source = await db.insertSource(
        SourcesCompanion.insert(
          name: 'Library',
          serverUrl: '',
          username: '',
          password: '',
        ),
      );
      final works = [
        for (var i = 0; i < 60; i++)
          LibraryWork(CatalogKind.vod, i, 'Movie $i', category: 'Drama'),
      ];
      await db.replaceMovies(source, [
        for (final w in works)
          MoviesCompanion.insert(
            sourceId: source,
            streamId: w.id,
            name: w.name,
          ),
      ]);
      var scans = 0;
      Future<HomeFeed> visit(DateTime time) async {
        final session = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            discoveryClientProvider.overrideWithValue(null),
            recommendationNowProvider.overrideWithValue(() => time),
            homeRankingLoaderProvider(source).overrideWith(
              (_) => (activity, extras, day, seed, exposure) async {
                scans++;
                return rankHome(
                  works,
                  activity,
                  extras,
                  day,
                  daySeed: seed,
                  recentFeatures: exposure,
                  limit: 48,
                );
              },
            ),
          ],
        );
        try {
          final provider = homeFeedProvider(source);
          session.listen(provider, (_, _) {});
          return await session.read(provider.future);
        } finally {
          session.dispose();
        }
      }

      final first = await visit(DateTime(2026, 11, 23, 5));
      final late = await visit(DateTime(2026, 11, 23, 23, 59));
      expect(first.movies.length, 24);
      expect(late.movies.map((m) => m.title), first.movies.map((m) => m.title));
      expect(scans, 1);
      final next = await visit(DateTime(2026, 11, 24));
      expect(scans, 2);
      expect(
        next.featured
            .map((p) => p.title)
            .toSet()
            .intersection(first.featured.map((p) => p.title).toSet()),
        isEmpty,
      );
    },
  );

  test(
    'Home shows saved recommendations during a slow daily refresh',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final source = await db.insertSource(
        SourcesCompanion.insert(
          name: 'Library',
          serverUrl: '',
          username: '',
          password: '',
        ),
      );
      final old = LibraryWork(CatalogKind.vod, 11, 'Saved recommendation');
      final fresh = LibraryWork(CatalogKind.vod, 12, 'New recommendation');
      await db.replaceMovies(source, [
        for (final work in [old, fresh])
          MoviesCompanion.insert(
            sourceId: source,
            streamId: work.id,
            name: work.name,
          ),
      ]);
      await DailyCache(db).get(
        (source: source, slot: 'home.v1'),
        '2026-11-23',
        (_) async => packHome(rankHome([old], [], {}, DateTime(2026, 11, 23))),
      );
      final refresh = Completer<void>();
      final visible = Completer<HomeFeed>();
      final scope = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          discoveryClientProvider.overrideWithValue(null),
          recommendationNowProvider.overrideWithValue(
            () => DateTime(2026, 11, 24),
          ),
          homeRankingLoaderProvider(source).overrideWith(
            (_) => (activity, extras, day, seed, exposure) async {
              await refresh.future;
              return rankHome([fresh], activity, extras, day);
            },
          ),
        ],
      );
      try {
        scope.listen(homeDisplayFeedProvider(source), (_, feed) {
          if (feed != null && !visible.isCompleted) visible.complete(feed);
        });
        expect((await visible.future).movies.single.id, old.id);
        refresh.complete();
        expect(
          (await scope.read(homeFeedProvider(source).future)).movies.single.id,
          fresh.id,
        );
      } finally {
        if (!refresh.isCompleted) refresh.complete();
        scope.dispose();
        await db.close();
      }
    },
  );

  testWidgets('TV charts wait until their section scrolls into view', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final api = TestCharts();
    final scroll = ScrollController();
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          chartSourcesProvider.overrideWithValue(api),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: scroll,
              child: const Column(
                children: [
                  SizedBox(height: 850),
                  TopChartsSection(
                    source: 1,
                    formFactor: FormFactor.tv,
                    loadWhenVisible: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await t.pump(const Duration(seconds: 2));
    expect(api.reads, 0);
    expect(find.byType(TopChartsSection, skipOffstage: false), findsOneWidget);
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await t.pump();
    await t.pumpAndSettle();
    expect(api.reads, 1);
    await t.pumpWidget(const SizedBox());
    scroll.dispose();
    await db.close();
  });

  for (final size in [
    const Size(390, 844),
    const Size(1280, 800),
    const Size(1920, 1080),
  ]) {
    testWidgets(
      'Top 10 switches markets, periods and formats at ${size.width}',
      (t) async {
        SharedPreferences.setMockInitialValues({});
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final db = AppDatabase.forTesting(NativeDatabase.memory()),
            api = TestCharts()..offline = size.width == 390;
        for (final name in ['Library', 'Other']) {
          await db.insertSource(
            SourcesCompanion.insert(
              name: name,
              serverUrl: '',
              username: '',
              password: '',
            ),
          );
        }
        await db.replaceMovies(1, [
          MoviesCompanion.insert(
            sourceId: 1,
            streamId: 12,
            name: 'Jordan film 3',
          ),
        ]);
        await db.replaceMovies(2, [
          MoviesCompanion.insert(
            sourceId: 2,
            streamId: 19,
            name: 'Jordan film 1',
          ),
        ]);
        await db.replaceSeries(1, [
          for (final (i, name) in [
            (3, 'Jordan show 2'),
            (7, 'Monthly series 4'),
            (9, 'World series 2'),
          ])
            SeriesItemsCompanion.insert(sourceId: 1, seriesId: i, name: name),
        ]);
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => Scaffold(
                body: SingleChildScrollView(
                  child: TopChartsSection(
                    source: 1,
                    formFactor: size.width < 500
                        ? FormFactor.mobile
                        : FormFactor.desktop,
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/series/:id',
              builder: (_, s) =>
                  Scaffold(body: Text('Opened ${s.pathParameters['id']}')),
            ),
          ],
        );
        final scope = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            chartSourcesProvider.overrideWithValue(api),
          ],
        );
        try {
          await t.pumpWidget(
            UncontrolledProviderScope(
              container: scope,
              child: MaterialApp.router(routerConfig: router),
            ),
          );
          Future<void> frames() async {
            for (var i = 0; i < 5; i++) {
              await t.pump(const Duration(milliseconds: 160));
            }
          }

          await frames();
          if (size.width == 390) {
            expect(find.text('The chart is unavailable.'), findsOneWidget);
            api.offline = false;
            await t.tap(find.text('Retry'));
            await frames();
          }
          expect(find.text('03'), findsWidgets);
          expect(find.text('Jordan film 3'), findsOneWidget);
          expect(find.text('Jordan film 1'), findsNothing);
          expect(find.text('Jordan film 2'), findsNothing);
          await t.tap(find.text('Series').first);
          await frames();
          expect(find.text('Jordan show 2'), findsOneWidget);
          expect(api.reads, size.width == 390 ? 2 : 1);
          final month = find.text('This month');
          if (size.width == 390) {
            await t.tap(month);
          } else {
            Focus.of(t.element(month)).requestFocus();
            await t.pump();
            await t.sendKeyEvent(LogicalKeyboardKey.enter);
          }
          await frames();
          expect(find.text('Monthly series 4'), findsOneWidget);
          expect(
            find.ancestor(
              of: month,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Ink &&
                    widget.decoration is ShapeDecoration &&
                    (widget.decoration as ShapeDecoration).gradient ==
                        AppColors.selectionGradient,
              ),
            ),
            findsOneWidget,
          );
          await t.tap(find.text('Jordan').first);
          await frames();
          final worldwide = find.widgetWithText(
            CheckedPopupMenuItem<String>,
            'Worldwide',
          );
          await t.ensureVisible(worldwide);
          await frames();
          await t.tap(worldwide);
          await frames();
          expect(find.text('Worldwide').first, findsOneWidget);
          await t.tap(find.text('Today'));
          await frames();
          expect(find.text('World series 2'), findsOneWidget);
          if (size.width < 500) {
            await t.tap(find.text('World series 2'));
          } else {
            Focus.of(t.element(find.text('World series 2'))).requestFocus();
            await t.pump();
            await t.sendKeyEvent(LogicalKeyboardKey.enter);
          }
          await frames();
          expect(router.state.uri.path, '/series/9');
          router.pop();
          await frames();
          await db.replaceSeries(1, []);
          await frames();
          expect(find.text('World series 2'), findsNothing);
          expect(
            find.textContaining('None of these chart titles'),
            findsOneWidget,
          );
          expect(t.takeException(), isNull);
        } finally {
          await t.pumpWidget(const SizedBox());
          router.dispose();
          scope.dispose();
          final closing = db.close();
          await t.pump(const Duration(seconds: 11));
          await closing;
        }
      },
    );
  }
  testWidgets(
    'slideshow respects reduced motion, offscreen and background states',
    (t) async {
      final scroll = ScrollController();
      int advances = 0;
      Widget view({bool reduced = false}) => MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: Scaffold(
              body: ListView(
                controller: scroll,
                children: [
                  SpotlightRotation(
                    slide: 1,
                    index: 0,
                    count: 3,
                    onMove: (_) => advances++,
                    builder: (nav, _) => SizedBox(
                      height: 340,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: nav,
                      ),
                    ),
                  ),
                  const SizedBox(height: 1600),
                ],
              ),
            ),
          ),
        ),
      );
      await t.pumpWidget(view(reduced: true));
      await t.pump(const Duration(seconds: 15));
      expect(advances, 0);
      expect(find.byTooltip('Pause slideshow'), findsNothing);
      await t.tap(find.byTooltip('Next top pick'));
      expect(advances, 1);
      await t.pumpWidget(view());
      await t.pump();
      scroll.jumpTo(250);
      await t.pump(const Duration(seconds: 12));
      expect(advances, 1);
      scroll.jumpTo(0);
      await t.pump();
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump(const Duration(seconds: 12));
      expect(advances, 1);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump(const Duration(seconds: 10));
      expect(advances, 2);
      await t.pumpWidget(const SizedBox());
      scroll.dispose();
    },
  );
  testWidgets(
    'banner advances on a daypart change and daily clock updates across midnight',
    (t) async {
      var now = DateTime(2026, 11, 23, 14);
      final works = [
        for (var i = 0; i < 6; i++)
          HomePick(
            LibraryWork(CatalogKind.series, i, 'Show $i'),
            10,
            'From your library',
            {},
            '',
          ),
      ];
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final scope = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          recommendationNowProvider.overrideWithValue(() => now),
          homeDisplayFeedProvider(
            1,
          ).overrideWithValue((movies: [], series: works, featured: works)),
        ],
      );
      try {
        await t.pumpWidget(
          UncontrolledProviderScope(
            container: scope,
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: HomeSpotlight(
                    source: 1,
                    formFactor: FormFactor.desktop,
                    fallback: null,
                    welcome: MediaItem(title: 'Welcome'),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.pump();
        String title() =>
            t.widget<HeroBanner>(find.byType(HeroBanner)).item.title;
        final first = title();
        await t.pump(const Duration(seconds: 10));
        await t.pump();
        expect(title(), isNot(first));
        await t.tap(find.byTooltip('Pause slideshow'));
        final stopped = title();
        await t.pump(const Duration(seconds: 12));
        expect(title(), stopped);
        await t.tap(find.byTooltip('Next top pick'));
        await t.pump();
        expect(title(), isNot(first));
        now = DateTime(2026, 11, 23, 20);
        scope.read(homeTimeProvider.notifier).refresh();
        await t.pump();
        expect(title(), 'Show 5');
        now = DateTime(2026, 11, 24, 0, 1);
        scope.read(homeTimeProvider.notifier).refresh();
        await t.pump();
        expect(title(), 'Show 0');
        expect(scope.read(recommendationDayProvider), '2026-11-24');
      } finally {
        await t.pumpWidget(const SizedBox());
        scope.dispose();
        await t.pump(const Duration(seconds: 1));
        await db.close();
      }
    },
  );
}
