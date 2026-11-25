import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zauxoflix/core/input/input_modality.dart';
import 'package:zauxoflix/core/models/media_item.dart';
import 'package:zauxoflix/core/responsive/form_factor.dart';
import 'package:zauxoflix/core/theme/app_theme.dart';
import 'package:zauxoflix/core/widgets/app_background.dart';
import 'package:zauxoflix/core/widgets/catalog_row_card.dart';
import 'package:zauxoflix/data/backend/auth_models.dart';
import 'package:zauxoflix/data/backend/backend_providers.dart';
import 'package:zauxoflix/data/backend/key_value_store.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/providers.dart';
import 'package:zauxoflix/features/home/widgets/poster_card.dart';
import 'package:zauxoflix/features/search/search_history.dart';
import 'package:zauxoflix/features/search/search_screen.dart';

class _MemoryStore implements KeyValueStore {
  final values = <String, String>{};
  bool failWrites = false;

  @override
  Future<void> delete(String key) async => values.remove(key);
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw const FormatException('Storage unavailable');
    values[key] = value;
  }
}

class _Viewer extends AuthController {
  @override
  AuthState build() =>
      const Authenticated(BackendUser(id: 'viewer', email: 'demo@example.com'));
}

class _TvLayout extends FormFactorOverride {
  @override
  FormFactor build() => FormFactor.tv;
}

void main() {
  final iconFont = Platform.environment['SEARCH_QA_MATERIAL_FONT'];
  if (iconFont != null) {
    setUpAll(() async {
      for (final (family, path) in [
        ('DM Sans', 'assets/fonts/DMSans-Regular.ttf'),
        ('DM Sans', 'assets/fonts/DMSans-Bold.ttf'),
        ('MaterialIcons', iconFont),
      ]) {
        final data = ByteData.sublistView(await File(path).readAsBytes());
        await (FontLoader(family)..addFont(Future.value(data))).load();
      }
      Directory('build/search-previews').createSync(recursive: true);
    });
  }

  test(
    'stores bounded, deduplicated history across sessions and scopes',
    () async {
      final store = _MemoryStore();
      const scope = (viewer: 'viewer', sourceId: 1);
      ProviderContainer session() => ProviderContainer(
        overrides: [keyValueStoreProvider.overrideWithValue(store)],
      );
      final first = session();
      final controller = first.read(searchHistoryProvider(scope).notifier);
      const movie = MediaItem(
        title: 'North Star',
        type: MediaType.movie,
        id: 7,
      );
      const series = MediaItem(
        title: 'North Shore',
        type: MediaType.series,
        id: 7,
      );
      await Future.wait([
        controller.record(query: '  North  ', item: movie),
        controller.record(query: 'NORTH', item: series),
        controller.record(item: movie),
      ]);
      first.dispose();

      final second = session();
      addTearDown(second.dispose);
      final history = await second.read(searchHistoryProvider(scope).future);
      expect(history.queries, ['NORTH']);
      expect(history.opened, [
        (type: MediaType.movie, id: 7),
        (type: MediaType.series, id: 7),
      ]);
      for (final other in [
        (viewer: 'another viewer', sourceId: 1),
        (viewer: 'viewer', sourceId: 2),
      ]) {
        final isolated = await second.read(searchHistoryProvider(other).future);
        expect(isolated.queries, isEmpty);
        expect(isolated.opened, isEmpty);
      }
      final restored = second.read(searchHistoryProvider(scope).notifier);
      store.failWrites = true;
      await expectLater(restored.clear(opened: true), throwsFormatException);
      expect(
        second.read(searchHistoryProvider(scope)).value!.opened,
        history.opened,
      );
      store.failWrites = false;
      await restored.clear(opened: true);
      await Future.wait([
        for (var i = 0; i < 16; i++) restored.record(query: 'Search $i'),
      ]);
      final trimmed = await second.read(searchHistoryProvider(scope).future);
      expect(trimmed.opened, isEmpty);
      expect(
        trimmed.queries,
        List.generate(SearchHistory.limit, (i) => 'Search ${15 - i}'),
      );
    },
  );

  for (final tv in [false, true]) {
    testWidgets(
      'global search remembers queries and opens history on ${tv ? 'TV' : 'phone'}',
      (tester) async {
        final previousInput = InputModality.usesDpad;
        InputModality.dpad.value = tv;
        addTearDown(() => InputModality.dpad.value = previousInput);
        tester.view.physicalSize = tv
            ? const Size(1280, 720)
            : const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final source = (await tester.runAsync(() async {
          final sourceId = await db.insertSource(
            SourcesCompanion.insert(
              name: 'Sample playlist',
              serverUrl: '',
              username: '',
              password: '',
            ),
          );
          await db.replaceMovies(sourceId, [
            MoviesCompanion.insert(
              sourceId: sourceId,
              streamId: 7,
              name: 'North Star',
            ),
          ]);
          await db.replaceSeries(sourceId, [
            SeriesItemsCompanion.insert(
              sourceId: sourceId,
              seriesId: 7,
              name: 'North Shore',
            ),
          ]);
          if (!tv) {
            await db.replaceLiveChannels(sourceId, [
              LiveChannelsCompanion.insert(
                sourceId: sourceId,
                streamId: 7,
                name: 'Evening News',
                streamUrl: const Value('https://example.invalid/live.ts'),
              ),
            ]);
          }
          return db.watchActiveSource().first;
        }))!;
        final store = _MemoryStore();
        final router = GoRouter(
          initialLocation: '/search',
          routes: [
            GoRoute(
              path: '/search',
              builder: (_, _) =>
                  const Scaffold(body: AppBackground(child: SearchScreen())),
            ),
            for (final kind in ['movie', 'series'])
              GoRoute(
                path: '/$kind/:id',
                builder: (_, _) => Scaffold(body: Text('$kind details')),
              ),
            GoRoute(
              path: '/player',
              builder: (_, _) => const Scaffold(body: Text('live player')),
            ),
          ],
        );
        final boundary = GlobalKey();
        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            keyValueStoreProvider.overrideWithValue(store),
            authControllerProvider.overrideWith(_Viewer.new),
            activeSourceProvider.overrideWith((ref) => Stream.value(source)),
            playbackUrlsProvider.overrideWithValue(const PlaybackUrls(null)),
            if (tv) formFactorOverrideProvider.overrideWith(_TvLayout.new),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: RepaintBoundary(
              key: boundary,
              child: MaterialApp.router(
                routerConfig: router,
                theme: AppTheme.dark,
                debugShowCheckedModeBanner: false,
              ),
            ),
          ),
        );
        Future<void> settle() async {
          await tester.pump();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 60)),
          );
          await tester.pumpAndSettle();
        }

        final field = find.byType(TextField);
        final historyProvider = searchHistoryProvider((
          viewer: 'viewer',
          sourceId: source.id,
        ));
        await settle();
        await tester.enterText(field, 'Nor');
        await tester.pump(const Duration(milliseconds: 350));
        await settle();
        expect(container.read(historyProvider).value!.queries, isEmpty);

        await tester.enterText(field, 'North');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await settle();
        expect(container.read(historyProvider).value!.queries, ['North']);
        final result = find.byWidgetPredicate(
          (w) =>
              w is PosterCard &&
              w.item.type == (tv ? MediaType.series : MediaType.movie),
        );
        await tester.ensureVisible(result);
        await tester.tap(result);
        await settle();
        expect(
          find.text(tv ? 'series details' : 'movie details'),
          findsOneWidget,
        );
        router.pop();
        await settle();
        await tester.tap(find.byTooltip('Clear search'));
        await settle();
        expect(find.text('Recent searches'), findsOneWidget);
        expect(find.text('Recently opened'), findsOneWidget);
        final opened = find.byType(CatalogRowCard);
        expect(opened, findsOneWidget);
        expect(
          tester.widget<CatalogRowCard>(opened).title,
          tv ? 'North Shore' : 'North Star',
        );
        if (iconFont != null) {
          await tester.runAsync(() async {
            final box =
                boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await box.toImage();
            final png = (await image.toByteData(
              format: ui.ImageByteFormat.png,
            ))!;
            await File(
              'build/search-previews/${tv ? 'tv' : 'phone'}.png',
            ).writeAsBytes(png.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.tap(opened);
        await settle();
        expect(
          find.text(tv ? 'series details' : 'movie details'),
          findsOneWidget,
        );
        router.pop();
        await settle();
        final recentQuery = find.widgetWithText(TextButton, 'North');
        if (tv) {
          FocusManager.instance.rootScope.descendants
              .firstWhere((node) => node.debugLabel == 'DpadTextField.outer')
              .requestFocus();
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pump();
          expect(
            FocusManager.instance.primaryFocus!.rect.contains(
              tester.getCenter(recentQuery),
            ),
            isTrue,
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.select);
        } else {
          await tester.tap(recentQuery);
        }
        await settle();
        expect(tester.widget<TextField>(field).controller!.text, 'North');
        expect(result, findsOneWidget);
        await tester.tap(find.byTooltip('Clear search'));
        await settle();
        await tester.tap(find.text('Clear').first);
        await settle();
        expect(find.text('Recent searches'), findsNothing);
        expect(find.text('Recently opened'), findsOneWidget);
        if (!tv) {
          await tester.enterText(field, 'Evening');
          await tester.pump(const Duration(milliseconds: 350));
          await settle();
          await tester.tap(find.byType(PosterCard));
          await settle();
          expect(find.text('live player'), findsOneWidget);
          router.pop();
          await settle();
          await tester.tap(find.byTooltip('Clear search'));
          await settle();
          expect(find.text('Evening'), findsOneWidget);
          final live = find.byWidgetPredicate(
            (w) => w is CatalogRowCard && w.title == 'Evening News',
          );
          await tester.tap(live);
          await settle();
          expect(find.text('live player'), findsOneWidget);
          router.pop();
          await settle();
          await tester.tap(find.text('Clear').last);
          await settle();
          expect(find.text('Recently opened'), findsNothing);
          expect(find.text('Evening'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        router.dispose();
        container.dispose();
        await tester.runAsync(db.close);
      },
    );
  }
}
