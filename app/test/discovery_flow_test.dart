import 'package:zauxoflix/data/discovery/home_feed.dart';
import 'package:zauxoflix/features/home/widgets/hero_banner.dart';
import 'package:zauxoflix/features/home/widgets/poster_card.dart';
import 'package:zauxoflix/features/home/widgets/content_rail.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zauxoflix/core/responsive/form_factor.dart';
import 'package:zauxoflix/core/theme/app_theme.dart';
import 'package:zauxoflix/data/backend/backend_providers.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/discovery/discovery_repository.dart';
import 'package:zauxoflix/data/providers.dart';
import 'package:zauxoflix/features/details/series_details_screen.dart';
import 'package:zauxoflix/features/details/movie_details_screen.dart';
import 'package:zauxoflix/features/details/trailer_screen.dart';
import 'package:zauxoflix/features/home/home_screen.dart';
import '../tool/discovery_preview.dart' as preview;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory cache;
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUpAll(() {
    cache = Directory.systemTemp.createTempSync('zauxoflix_discovery_images_');
    messenger.setMockMethodCallHandler(pathChannel, (call) async => cache.path);
  });
  tearDownAll(() {
    messenger.setMockMethodCallHandler(pathChannel, null);
    cache.deleteSync(recursive: true);
  });
  for (final (device, size) in [
    ('phone', const Size(390, 844)),
    ('desktop', const Size(1280, 800)),
    ('tv', const Size(1920, 1080)),
  ]) {
    testWidgets(
      '$device discovery opens, resumes navigation and reacts to My List',
      (tester) async {
        const base = 'https://preview.invalid';
        final output = Platform.environment['ZAUXOFLIX_CAPTURE_DIR'];
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final source = await preview.seedPreview(db, base);
        var enabled = false;
        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            homeIndexPathProvider.overrideWith((_) async => null),
            discoveryClientProvider.overrideWith(
              (_) => enabled ? preview.PreviewDiscovery() : null,
            ),
            xtreamApiProvider.overrideWithValue(preview.PreviewApi(base)),
            authControllerProvider.overrideWith(preview.PreviewAuth.new),
            trailerEmbedAvailableProvider.overrideWith((_) async => false),
          ],
        );
        if (device == 'tv') {
          container
              .read(formFactorOverrideProvider.notifier)
              .set(FormFactor.tv);
        }
        final router = GoRouter(
          initialLocation: '/series/1',
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, _) => const Scaffold(body: HomeScreen()),
            ),
            GoRoute(
              path: '/movie/:id',
              builder: (_, state) => MovieDetailsScreen(
                streamId: int.parse(state.pathParameters['id']!),
              ),
            ),
            GoRoute(
              path: '/series/:id',
              builder: (_, state) => SeriesDetailsScreen(
                seriesId: int.parse(state.pathParameters['id']!),
              ),
            ),
          ],
        );
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final boundary = GlobalKey();
        Future<void> frames() async {
          for (var i = 0; i < 5; i++) {
            await tester.pump(const Duration(milliseconds: 180));
          }
        }

        Future<void> capture(String stage) async {
          if (output == null) return;
          await tester.runAsync(() async {
            final render =
                boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await render.toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await File(
              '$output/$device-$stage.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }

        try {
          if (output != null) {
            await tester.runAsync(() async {
              await Directory(output).create(recursive: true);
              for (final (family, file) in [
                ('DM Sans', 'assets/fonts/DMSans-Regular.ttf'),
                ('DM Sans', 'assets/fonts/DMSans-Bold.ttf'),
                (
                  'MaterialIcons',
                  '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
                ),
              ]) {
                final font = FontLoader(family)
                  ..addFont(
                    Future.value(
                      ByteData.sublistView(await File(file).readAsBytes()),
                    ),
                  );
                await font.load();
              }
              final bytes = await preview.artwork(1);
              final codec = await ui.instantiateImageCodec(
                Uint8List.fromList(bytes),
              );
              final image = (await codec.getNextFrame()).image;
              for (final width in [440, 1280]) {
                final provider = ResizeImage.resizeIfNeeded(
                  width,
                  null,
                  const CachedNetworkImageProvider('$base/art/1'),
                );
                final key = await provider.obtainKey(ImageConfiguration.empty);
                PaintingBinding.instance.imageCache.putIfAbsent(
                  key,
                  () => OneFrameImageStreamCompleter(
                    Future.value(ImageInfo(image: image.clone())),
                  ),
                );
              }
              image.dispose();
              codec.dispose();
            });
          }
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: RepaintBoundary(
                key: boundary,
                child: MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  routerConfig: router,
                  theme: AppTheme.dark,
                ),
              ),
            ),
          );
          await frames();
          expect(find.text('Watch trailer'), findsNothing);
          await capture('before');
          enabled = true;
          container.invalidate(discoveryClientProvider);
          await frames();
          expect(find.textContaining('Trakt 8.4/10'), findsOneWidget);
          expect(find.text('View on IMDb'), findsOneWidget);
          await capture('after');
          await tester.tap(find.text('Watch trailer'));
          await frames();
          expect(find.text('Open in YouTube'), findsOneWidget);
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await frames();
          expect(find.text('Watch trailer'), findsOneWidget);
          expect(await db.select(db.playbackPositions).get(), isEmpty);
          await tester.tap(find.text('My List'));
          await frames();
          final season = find.text('Season 2');
          await tester.ensureVisible(season);
          await tester.tap(season);
          await frames();
          final related = find.text('More like this');
          await tester.ensureVisible(related);
          await tester.tap(related);
          await frames();
          final silo = find.text('Silo').first;
          await tester.ensureVisible(silo);
          await tester.tap(silo);
          await frames();
          expect(router.state.uri.path, '/series/2');
          router.pop();
          await frames();
          expect(find.text('Silo'), findsWidgets);
          await tester.ensureVisible(find.text('Episodes'));
          await tester.tap(find.text('Episodes'));
          await frames();
          expect(
            tester
                .widget<FilterChip>(find.widgetWithText(FilterChip, 'Season 2'))
                .selected,
            isTrue,
          );
          router.go('/home');
          await frames();
          final banner = find.byType(HeroBanner);
          final before = tester.widget<HeroBanner>(banner).item.title;
          final next = find.byTooltip('Next top pick');
          expect(next, findsOneWidget);
          await tester.ensureVisible(next);
          if (device == 'phone') {
            await tester.tap(next);
          } else {
            Focus.of(
              tester.element(
                find
                    .descendant(
                      of: next,
                      matching: find.byIcon(Icons.chevron_right),
                    )
                    .first,
              ),
            ).requestFocus();
            await tester.pump();
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          }
          await frames();
          expect(tester.widget<HeroBanner>(banner).item.title, isNot(before));
          Scrollable.of(tester.element(banner)).position.jumpTo(0);
          await frames();
          await capture('featured-home');
          final rows = find.byType(ContentRail);
          final list = find.byType(ListView).first;
          for (final heading in ['Recommended movies', 'Recommended series']) {
            for (
              var i = 0;
              i < 14 && find.text(heading).evaluate().isEmpty;
              i++
            ) {
              await tester.drag(list, const Offset(0, -260));
              await frames();
            }
            final title = find.text(heading);
            await tester.ensureVisible(title);
            await frames();
            final rail = tester
                .widgetList<ContentRail>(rows)
                .singleWhere((r) => r.title == heading);
            expect(rail.items, isNotEmpty);
            expect(
              rail.items.every(
                (item) =>
                    item.kindLabel ==
                    (heading.endsWith('movies') ? 'Movie' : 'Series'),
              ),
              isTrue,
            );
          }
          final movieHeading = find.text('Recommended movies');
          if (movieHeading.evaluate().isNotEmpty) {
            await tester.ensureVisible(movieHeading);
            await frames();
          }
          await capture('personalized-home');
          final seriesRail = find
              .widgetWithText(ContentRail, 'Recommended series')
              .first;
          final firstCard = find
              .descendant(of: seriesRail, matching: find.byType(PosterCard))
              .first;
          final expectedId = tester.widget<PosterCard>(firstCard).item.id;
          await tester.ensureVisible(firstCard);
          await tester.tap(firstCard);
          await frames();
          expect(router.state.uri.path, '/series/$expectedId');
          router.pop();
          await frames();
          await db.removeFavorite(source, CatalogKind.series, 1);
          await frames();
          final refreshed = await container.read(
            homeFeedProvider(source).future,
          );
          expect(
            refreshed.series.any(
              (item) => item.reason == 'Because you saved Severance',
            ),
            isFalse,
          );
          router.go('/movie/11');
          await frames();
          final nextMovie = find.text('Midnight Signal');
          await tester.ensureVisible(nextMovie);
          await tester.tap(nextMovie);
          await frames();
          expect(router.state.uri.path, '/movie/12');
          router.pop();
          await frames();
          expect(find.text('More like this'), findsOneWidget);
        } finally {
          await tester.pumpWidget(const SizedBox());
          router.dispose();
          container.dispose();
          final close = db.close();
          // The image cache schedules cleanup ten seconds after the last poster request.
          await tester.pump(const Duration(seconds: 11));
          await close;
        }
      },
    );
  }
}
