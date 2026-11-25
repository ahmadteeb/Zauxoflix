import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zauxoflix/core/input/input_modality.dart';
import 'package:zauxoflix/core/responsive/form_factor.dart';
import 'package:zauxoflix/core/theme/app_theme.dart';
import 'package:zauxoflix/core/widgets/app_background.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/providers.dart';
import 'package:zauxoflix/features/browse/browse_screen.dart';
import 'package:zauxoflix/features/home/widgets/poster_card.dart';

class _TvForm extends FormFactorOverride {
  @override
  FormFactor build() => FormFactor.tv;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final iconFont = Platform.environment['BROWSE_QA_MATERIAL_FONT'];
  if (iconFont != null) {
    setUpAll(() async {
      for (final (family, paths) in [
        (
          'DM Sans',
          ['assets/fonts/DMSans-Regular.ttf', 'assets/fonts/DMSans-Bold.ttf'],
        ),
        (
          'IBM Plex Sans Arabic',
          ['assets/fonts/IBMPlexSansArabic-Regular.ttf'],
        ),
        ('MaterialIcons', [iconFont]),
      ]) {
        final font = FontLoader(family);
        for (final path in paths) {
          font.addFont(File(path).readAsBytes().then(ByteData.sublistView));
        }
        await font.load();
      }
      Directory('build/browse-previews').createSync(recursive: true);
    });
  }

  for (final tv in [false, true]) {
    testWidgets('catalog filters and details on ${tv ? 'TV' : 'phone'}', (
      tester,
    ) async {
      if (!tv) {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
      } else {
        final previous = InputModality.dpad.value;
        InputModality.dpad.value = true;
        addTearDown(() => InputModality.dpad.value = previous);
      }
      tester.view.physicalSize = tv
          ? const Size(1280, 720)
          : const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final kind = tv ? CatalogKind.series : CatalogKind.vod;
      final local = tv ? 'مسلسلات عربية' : 'أفلام عربية';
      const other = 'International';
      final source = (await tester.runAsync(() async {
        final id = await db.insertSource(
          SourcesCompanion.insert(
            name: 'Fixture playlist',
            serverUrl: 'https://example.invalid',
            username: '',
            password: '',
          ),
        );
        await db.replaceCategories(id, kind, [
          for (final (key, label) in [('local', local), ('intl', other)])
            CategoriesCompanion.insert(
              sourceId: id,
              kind: kind,
              categoryId: key,
              name: label,
            ),
        ]);
        final titles = [
          ('Skyline', 'local', 7.0),
          ('The Bridge', 'intl', 8.0),
          ('The Vineyard', 'intl', 8.5),
          ('North Star', 'local', 9.0),
          ('The Last Train', 'intl', 7.0),
          ('Sea of Light', 'local', 8.5),
          ('Paper Moon', 'local', 7.0),
          ('Autumn Road', 'intl', 6.0),
          ('Échos', 'intl', 7.5),
          ('هَاري بوتر', 'local', 8.2),
          ('هَاري بوتر 2', 'intl', 10.0),
        ];
        if (tv) {
          await db.replaceSeries(id, [
            for (final (index, row) in titles.indexed)
              SeriesItemsCompanion.insert(
                sourceId: id,
                seriesId: index + 1,
                name: row.$1,
                categoryId: Value(row.$2),
                rating: Value(row.$3),
              ),
          ]);
        } else {
          await db.replaceMovies(id, [
            for (final (index, row) in titles.indexed)
              MoviesCompanion.insert(
                sourceId: id,
                streamId: index + 1,
                name: row.$1,
                categoryId: Value(row.$2),
                rating: Value(row.$3),
              ),
            for (var i = 20; i < 88; i++)
              MoviesCompanion.insert(
                sourceId: id,
                streamId: i,
                name: 'Vault $i',
                categoryId: const Value('local'),
              ),
          ]);
        }
        return db.watchActiveSource().first;
      }))!;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: AppBackground(
                child: tv
                    ? const BrowseScreen.series()
                    : const BrowseScreen.movies(),
              ),
            ),
          ),
          GoRoute(
            path: '/${tv ? 'series' : 'movie'}/:id',
            builder: (_, state) =>
                Scaffold(body: Text('Details ${state.pathParameters['id']}')),
          ),
        ],
      );
      final frame = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            activeSourceProvider.overrideWith((ref) => Stream.value(source)),
            if (tv) formFactorOverrideProvider.overrideWith(_TvForm.new),
          ],
          child: RepaintBoundary(
            key: frame,
            child: MaterialApp.router(
              routerConfig: router,
              theme: AppTheme.dark,
              debugShowCheckedModeBanner: false,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
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

      Future<void> snapshot(String name) async {
        if (iconFont == null) return;
        await tester.runAsync(() async {
          final box =
              frame.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await box.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            'build/browse-previews/$name.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await settle();
      final page = tv ? 'series-tv' : 'movies-phone';
      expect(find.text(tv ? 'Series' : 'Movies'), findsOneWidget);
      expect(find.byType(PosterCard), findsWidgets);
      await snapshot(page);

      await tester.tap(find.text('All categories'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), tv ? 'مسلسلات' : 'افلام');
      await tester.pumpAndSettle();
      expect(find.text(other), findsNothing);
      await tester.tap(find.text(local));
      await settle();
      final filters = find.widgetWithText(TextButton, 'Filters (1)');
      if (tv) {
        tester.widget<TextButton>(filters).focusNode!.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.select);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(
          FocusManager.instance.primaryFocus?.debugLabel,
          'DpadTextField.outer',
        );
      } else {
        await tester.tap(filters);
        await tester.pumpAndSettle();
      }
      await snapshot('$page-filters');
      await tester.tap(find.text('Top rated'));
      await settle();
      expect(
        find.ancestor(
          of: find.text('Top rated'),
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
      String firstTitle() => tester
          .widgetList<PosterCard>(find.byType(PosterCard))
          .first
          .item
          .title;
      expect(firstTitle(), 'North Star');
      await tester.enterText(find.byType(TextField), 'Harry Potter');
      await tester.pump(const Duration(milliseconds: 230));
      await settle();
      expect(find.byType(PosterCard), findsOneWidget);
      expect(firstTitle(), 'هَاري بوتر');
      await tester.tap(find.text('Filters (3)'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Harry Potter · Top rated'), findsOneWidget);
      if (!tv) {
        tester.view.physicalSize = const Size(844, 390);
        await settle();
        expect(find.text(local), findsOneWidget);
        expect(firstTitle(), 'هَاري بوتر');
        await snapshot('movies-landscape');
        await tester.tap(find.text('Filters (3)'));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);
        await tester.ensureVisible(find.text('Top rated'));
        expect(tester.takeException(), isNull);
        final toggle = find.text('Filters (3)');
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.byType(PosterCard));
      await tester.tap(find.byType(PosterCard));
      await settle();
      expect(find.text('Details 10'), findsOneWidget);
      router.pop();
      await settle();
      final clear = find.text('Clear filters');
      await tester.ensureVisible(clear);
      await tester.tap(clear);
      await settle();
      expect(find.text('All categories'), findsOneWidget);
      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'nonexistent title');
      await tester.pump(const Duration(milliseconds: 230));
      await settle();
      expect(find.text('No matching titles'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear title search'));
      await settle();
      expect(find.byType(PosterCard), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(db.close);
      if (!tv) debugDefaultTargetPlatformOverride = null;
    });
  }
}
