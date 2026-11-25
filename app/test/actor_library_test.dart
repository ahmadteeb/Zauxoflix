import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zauxoflix/core/models/media_item.dart';
import 'package:zauxoflix/core/widgets/media_artwork.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/discovery/actor_library.dart';
import 'package:zauxoflix/data/discovery/discovery_repository.dart';
import 'package:zauxoflix/data/discovery/imdb_index.dart';
import 'package:zauxoflix/data/discovery/trakt_client.dart';
import 'package:zauxoflix/data/providers.dart';
import 'package:zauxoflix/features/details/cast_gallery.dart';
import 'package:zauxoflix/features/details/actor_library_section.dart';
import 'package:zauxoflix/core/widgets/app_image.dart';

void main() {
  const ActorOrigin origin = (
    source: 1,
    kind: CatalogKind.vod,
    id: 7,
    external: 'tt0000007',
  );
  const query = (personId: 'nm0000432', origin: origin);
  const person = (
    id: 'nm0000432',
    name: 'Actor',
    characters: <String>[],
    birth: null,
    death: null,
    professions: <String>[],
    knownFor: <String>[],
  );
  test(
    'acting filmography calls movie and show endpoints and omits crew-only credits',
    () async {
      final api = TraktClient('test');
      addTearDown(api.dio.close);
      final paths = <String>[];
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (r, handler) {
            paths.add(r.path);
            expect(r.queryParameters['extended'], 'full');
            final work = {
              'title': 'A title',
              'original_title': 'Original',
              'year': 2020,
              'ids': {'trakt': 42, 'imdb': 'tt0000042', 'tmdb': 89},
              'images': {
                'poster': ['media.trakt.tv/titles/42/poster.webp'],
              },
            };
            final role = {r.path.endsWith('/movies') ? 'movie' : 'show': work};
            handler.resolve(
              Response<Object?>(
                requestOptions: r,
                data: {
                  'cast': [role],
                  'crew': {
                    'directing': [role, role],
                  },
                },
              ),
            );
          },
        ),
      );
      for (final k in [CatalogKind.vod, CatalogKind.series]) {
        final c = (await api.actingCredits(query.personId, k)).single;
        expect(
          (c.kind, c.original, c.poster),
          (k, 'Original', 'https://media.trakt.tv/titles/42/poster.webp'),
        );
      }
      expect(paths, ['/people/nm0000432/movies', '/people/nm0000432/shows']);
    },
  );
  test(
    'joins acting credits to this source, respecting local identities, aliases, years and duplicates',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          discoveryClientProvider.overrideWithValue(null),
          imdbActingCreditsProvider(query.personId).overrideWith(
            (_) async => const [
              ActingCredit(
                CatalogKind.vod,
                'Original film',
                2023,
                imdb: 'tt0000011',
                poster: 'https://media.trakt.tv/film.webp',
              ),
              ActingCredit(
                CatalogKind.series,
                'Red Buds',
                2023,
                original: 'Kizil Goncalar',
                imdb: 'tt0000012',
                tmdb: 100,
              ),
              ActingCredit(CatalogKind.vod, 'Origin', 2022, imdb: 'tt0000007'),
              ActingCredit(
                CatalogKind.vod,
                'Unavailable',
                1994,
                imdb: 'tt0000013',
              ),
            ],
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      for (final name in ['One', 'Two']) {
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
        for (final (id, name, ext) in [
          (7, 'Origin', 'tt0000007'),
          (8, 'Origin duplicate', 'tt0000007'),
          (9, 'Original film 2023', null),
          (10, 'Original film (1999)', null),
          (11, 'Original film 2023', 'tt0000999'),
          (12, 'Unavailable', null),
        ])
          MoviesCompanion.insert(
            sourceId: 1,
            streamId: id,
            name: name,
            externalId: Value(ext),
          ),
      ]);
      await db.replaceSeries(1, [
        SeriesItemsCompanion.insert(
          sourceId: 1,
          seriesId: 7,
          name: 'Kızıl Goncalar - البراعم الحمراء',
          releaseYear: const Value(2023),
          cover: const Value('https://example.test/poster.jpg'),
        ),
      ]);
      await db.replaceMovies(2, [
        MoviesCompanion.insert(
          sourceId: 2,
          streamId: 33,
          name: 'Elsewhere',
          externalId: const Value('tt0000013'),
        ),
      ]);
      await db.customStatement(
        'INSERT INTO discovery_entries(source_id,kind,item_id,fingerprint,payload,fetched_at) VALUES(?,?,?,?,?,?)',
        [1, 'vod', 9, '["Original film 2023",null,null]', '{', 1],
      );
      final p = actorLibraryProvider(query);
      container.listen(p, (_, _) {});
      final result = await container.read(p.future);
      expect(result.items.map((i) => (i.type, i.id, i.imageUrl)).toSet(), {
        (MediaType.movie, 9, 'https://media.trakt.tv/film.webp'),
        (MediaType.series, 7, 'https://example.test/poster.jpg'),
      });
    },
  );

  testWidgets('a failed library poster loads artwork for that exact title', (
    tester,
  ) async {
    const broken = 'https://example.test/blocked.webp';
    const fallback = 'https://media.trakt.tv/shows/12/poster.webp';
    final responses = <Completer<ImageInfo>>[];
    for (final url in [broken, fallback]) {
      final response = Completer<ImageInfo>();
      responses.add(response);
      final provider = ResizeImage.resizeIfNeeded(
        320,
        null,
        CachedNetworkImageProvider(url),
      );
      final key = await provider.obtainKey(ImageConfiguration.empty);
      PaintingBinding.instance.imageCache.putIfAbsent(
        key,
        () => OneFrameImageStreamCompleter(response.future),
      );
    }
    var requests = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          actorLibraryProvider(query).overrideWith(
            (_) => Stream.value((
              items: const [
                ActorLibraryTitle(
                  id: 12,
                  title: 'Other show',
                  type: MediaType.series,
                  subtitle: 'Series · 2023',
                  imageUrl: broken,
                  titleId: 'tt0000012',
                ),
              ],
              checking: false,
              incomplete: false,
            )),
          ),
          actorTitlePosterProvider((
            CatalogKind.series,
            'tt0000012',
          )).overrideWith((_) async {
            requests++;
            return fallback;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ActorLibrarySection(query: query)),
        ),
      ),
    );
    await tester.pump();
    expect(requests, 0);
    responses.first.completeError(StateError('403'));
    await tester.pump();
    await tester.pump();
    expect(requests, 1);
    expect(
      tester.widgetList<AppImage>(find.byType(AppImage)).map((i) => i.url),
      contains(fallback),
    );
    expect(find.text('Other show'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'unavailable credits can be retried and a verified empty library is explained',
    (t) async {
      var calls = 0;
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            actorLibraryProvider(query).overrideWith(
              (_) => Stream.value((
                items: const <ActorLibraryTitle>[],
                checking: false,
                incomplete: ++calls == 1,
              )),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ActorLibrarySection(query: query)),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      await t.tap(find.text('Retry'));
      await t.pumpAndSettle();
      expect(
        find.text('No other matching movies or series in this library.'),
        findsOneWidget,
      );
    },
  );
  for (final size in [
    const Size(390, 844),
    const Size(1280, 800),
    const Size(1920, 1080),
  ]) {
    testWidgets(
      'actor posters open the correct details route at ${size.width}',
      (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = size;
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.view.resetPhysicalSize);
        final container = ProviderContainer(
          overrides: [
            activeSourceProvider.overrideWith(
              (_) => Stream.value(
                const Source(
                  id: 1,
                  name: "Local",
                  sourceType: SourceType.xtream,
                  serverUrl: "",
                  username: "",
                  password: "",
                ),
              ),
            ),
            actorLibraryProvider(query).overrideWith(
              (_) => Stream.value((
                items: const [
                  ActorLibraryTitle(
                    id: 2,
                    title: 'Other movie',
                    type: MediaType.movie,
                    subtitle: 'Movie · 2020',
                  ),
                  ActorLibraryTitle(
                    id: 2,
                    title: 'Other series',
                    type: MediaType.series,
                    subtitle: 'Series · 2023',
                  ),
                ],
                checking: false,
                incomplete: false,
              )),
            ),
          ],
        );
        container.listen(activeSourceProvider, (_, _) {});
        await container.read(activeSourceProvider.future);
        final router = GoRouter(
          initialLocation: '/origin',
          routes: [
            GoRoute(
              path: '/origin',
              builder: (_, _) => const Scaffold(
                body: CastGallery(
                  title: 'Cast',
                  cast: [person],
                  photos: {},
                  origin: origin,
                ),
              ),
            ),
            for (final k in ['movie', 'series'])
              GoRoute(
                path: '/$k/:id',
                builder: (_, s) =>
                    Scaffold(body: Text('Details ${s.uri.path}')),
              ),
          ],
        );
        try {
          await t.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp.router(routerConfig: router),
            ),
          );
          await t.pumpAndSettle();
          for (final (label, route) in [
            ('Other movie', '/movie/2'),
            ('Other series', '/series/2'),
          ]) {
            await t.tap(find.text('Actor'));
            await t.pumpAndSettle();
            expect(find.text('In your library'), findsOneWidget);
            await t.ensureVisible(find.text(label));
            final button = find.widgetWithText(OutlinedButton, label);
            expect(
              find.descendant(of: button, matching: find.byType(MediaArtwork)),
              findsOneWidget,
            );
            if (route.startsWith('/series')) {
              Focus.of(t.element(find.text(label))).requestFocus();
              await t.pump();
              await t.sendKeyEvent(LogicalKeyboardKey.enter);
            } else {
              await t.tap(find.text(label));
            }
            await t.pumpAndSettle();
            expect(find.text('Details $route'), findsOneWidget);
            expect(find.byType(AlertDialog), findsNothing);
            router.pop();
            await t.pumpAndSettle();
            expect(find.text('Actor'), findsOneWidget);
          }
        } finally {
          await t.pumpWidget(const SizedBox());
          router.dispose();
          container.dispose();
        }
      },
    );
  }
}
