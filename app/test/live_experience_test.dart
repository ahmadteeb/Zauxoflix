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
import 'package:zauxoflix/core/responsive/form_factor.dart';
import 'package:zauxoflix/core/theme/app_theme.dart';
import 'package:zauxoflix/features/guide/epg_grid_screen.dart';
import 'package:zauxoflix/features/live/live_tv_screen.dart';
import 'package:zauxoflix/features/live/live_widgets.dart';
import 'package:zauxoflix/features/player/player_screen.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/live/live_directory.dart';
import 'package:zauxoflix/data/live/live_providers.dart';
import 'package:zauxoflix/data/live/regional_channels.dart';
import 'package:zauxoflix/data/providers.dart';

import 'support/auth_test_overrides.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final materialFont = Platform.environment['LIVE_QA_MATERIAL_FONT'];
  if (materialFont != null) {
    setUpAll(() async {
      for (final (family, path) in [
        ('DM Sans', 'assets/fonts/DMSans-Regular.ttf'),
        ('DM Sans', 'assets/fonts/DMSans-Bold.ttf'),
        ('MaterialIcons', materialFont),
      ]) {
        final bytes = ByteData.sublistView(await File(path).readAsBytes());
        await (FontLoader(family)..addFont(Future.value(bytes))).load();
      }
      Directory('build/live-redesign-previews').createSync(recursive: true);
    });
  }

  for (final (label, size, tv) in [
    ('phone', const Size(390, 844), false),
    ('tv', const Size(1920, 1080), true),
  ]) {
    testWidgets('grouped Live TV journey on $label', (tester) async {
      if (!tv) {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
      }
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final (sourceId, source, rows) = (await tester.runAsync(() async {
        final sourceId = await db.insertSource(
          SourcesCompanion.insert(
            name: 'Fixture',
            serverUrl: 'https://example.invalid',
            username: '',
            password: '',
          ),
        );
        await db.replaceCategories(sourceId, CatalogKind.live, [
          CategoriesCompanion.insert(
            sourceId: sourceId,
            kind: CatalogKind.live,
            categoryId: 'jordan',
            name: 'Jordanian channels',
          ),
        ]);
        await db.replaceLiveChannels(sourceId, [
          for (final (index, name) in [
            'JO | ROYA HD',
            'Roya FHD',
            'Al Mamlaka HD',
            'Jordan Sports HD',
            'Roya Kids HD',
            'MBC Masr HD',
            'Other Station HD',
            'beIN Sports 1 HD',
            'beIN Sports 1 FHD',
            'Al Kass One HD',
            'Tennis Channel HD',
          ].indexed)
            LiveChannelsCompanion.insert(
              sourceId: sourceId,
              streamId: index + 1,
              name: name,
              categoryId: index < 5
                  ? const Value('jordan')
                  : const Value.absent(),
              streamUrl: Value('https://example.invalid/$index'),
              epgChannelId: index < 2
                  ? const Value('roya')
                  : index == 7 || index == 8
                  ? const Value('bein1')
                  : const Value.absent(),
            ),
        ]);
        final now = DateTime.now();
        await db.insertEpgBatch([
          EpgProgrammesCompanion.insert(
            sourceId: sourceId,
            channelId: 'bein1',
            title: 'UEFA Champions League',
            startAt: now.subtract(const Duration(minutes: 15)),
            endAt: now.add(const Duration(minutes: 90)),
          ),
          for (final (name, start, end) in [
            ('Evening news', -15, 45),
            ('Jordan now', 45, 90),
          ])
            EpgProgrammesCompanion.insert(
              sourceId: sourceId,
              channelId: 'roya',
              title: name,
              startAt: now.add(Duration(minutes: start)),
              endAt: now.add(Duration(minutes: end)),
            ),
        ]);
        final source = await db.watchActiveSource().first;
        final rows = await db.watchLiveChannels(sourceId, limit: null).first;
        return (sourceId, source, rows);
      }))!;
      final directory = buildLiveDirectory(rows, []);
      final airing = (await tester.runAsync(
        () => db.nowPlaying(sourceId, DateTime.now()),
      ))!;
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          nowPlayingProvider.overrideWith((ref) => Stream.value(airing)),
          activeSourceProvider.overrideWith((ref) => Stream.value(source)),
          liveDirectoryProvider(
            sourceId,
          ).overrideWith((ref) => Stream.value(directory)),
          liveRegionProvider.overrideWith(() => _FixtureRegion()),
          authenticatedOverride,
          if (tv) formFactorOverrideProvider.overrideWith(_TvOverride.new),
        ],
      );
      PlayerArgs? played;
      final router = GoRouter(
        initialLocation: '/live',
        routes: [
          GoRoute(
            path: '/live',
            builder: (_, _) => const Scaffold(body: LiveTvScreen()),
          ),
          GoRoute(path: '/guide', builder: (_, _) => const EpgGridScreen()),
          GoRoute(
            path: '/player',
            builder: (_, state) {
              played = state.extra as PlayerArgs;
              return const Scaffold(body: Text('Opened player'));
            },
          ),
        ],
      );
      final boundary = GlobalKey();
      Future<void> snapshot(String screen) async {
        if (materialFont == null) return;
        await tester.runAsync(() async {
          final frame =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await frame.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            'build/live-redesign-previews/$label-$screen.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(
            key: boundary,
            child: MaterialApp.router(
              theme: AppTheme.dark,
              debugShowCheckedModeBanner: false,
              routerConfig: router,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(LiveStationRow, 'Roya TV'), findsOneWidget);
      expect(
        find.descendant(
          of: find.widgetWithText(LiveStationRow, 'Roya TV'),
          matching: find.textContaining('2 versions'),
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(LiveStationRow, 'Other Station'),
        findsNothing,
      );
      await snapshot('channels');

      final filterBars = find.byWidgetPredicate(
        (widget) => widget is LiveFilterBar,
      );
      Future<void> chooseList(String label) async {
        if (!tv) {
          await tester.tap(find.byTooltip('Choose channel list'));
          await tester.pumpAndSettle();
        }
        await tester.tap(
          tv
              ? find.descendant(of: filterBars, matching: find.text(label))
              : find.text(label),
        );
        await tester.pumpAndSettle();
      }

      if (tv) {
        await chooseList('Sports');
      } else {
        await tester.tap(find.byTooltip('Open Sports'));
        await tester.pumpAndSettle();
      }
      final bein = find.widgetWithText(LiveStationRow, 'beIN Sports 1');
      expect(find.text('Football on now'), findsOneWidget);
      expect(bein, findsOneWidget);
      expect(find.widgetWithText(LiveStationRow, 'Roya TV'), findsNothing);
      await snapshot('sports');
      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      final beinFilter = find.widgetWithText(TextButton, 'beIN SPORTS');
      await tester.ensureVisible(beinFilter);
      await tester.pumpAndSettle();
      await tester.tap(beinFilter);
      await tester.pumpAndSettle();
      expect(bein, findsOneWidget);
      expect(find.widgetWithText(LiveStationRow, 'Alkass 1'), findsNothing);
      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      if (tv) {
        final focus = Focus.of(
          tester.element(
            find.descendant(of: bein, matching: find.text('beIN Sports 1')),
          ),
        );
        focus.requestFocus();
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus, isNot(same(focus)));
        await tester.tap(find.byTooltip('Versions for beIN Sports 1'));
        await tester.pumpAndSettle();
        expect(find.text('1080p'), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
      } else {
        tester.view.physicalSize = const Size(844, 390);
        await tester.pumpAndSettle();
        expect(bein, findsOneWidget);
        await snapshot('sports-landscape');
        await tester.tap(bein);
        await tester.pumpAndSettle();
        expect(played?.items.map((item) => item.title), ['beIN Sports 1']);
        router.pop();
        await tester.pumpAndSettle();
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        played = null;
      }
      await tester.enterText(find.byType(TextField), 'Roya');
      await tester.pump(const Duration(milliseconds: 180));
      await tester.pumpAndSettle();
      expect(find.text('No channels found'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();

      await chooseList('Regional Picks');
      expect(find.text('Jordan'), findsOneWidget);
      expect(find.widgetWithText(LiveStationRow, 'MBC Masr'), findsNothing);
      final news = find.descendant(of: filterBars, matching: find.text('News'));
      expect(news, findsNothing);
      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      expect(news, findsOneWidget);
      await tester.tap(news);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(LiveStationRow, 'Al Mamlaka'), findsOneWidget);
      expect(find.widgetWithText(LiveStationRow, 'Roya TV'), findsNothing);
      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      expect(find.text('Jordan · News'), findsOneWidget);
      if (!tv) {
        tester.view.physicalSize = const Size(844, 390);
        await tester.pumpAndSettle();
        expect(find.text('Jordan · News'), findsOneWidget);
        final header = tester.getRect(find.text('TV Guide'));
        final channel = tester.getRect(
          find.widgetWithText(LiveStationRow, 'Al Mamlaka'),
        );
        expect(header.right, lessThan(channel.left));
        expect(tester.takeException(), isNull);
        await snapshot('landscape');
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
      }
      await chooseList('All Channels');
      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All categories'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jordanian channels'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(LiveStationRow, 'MBC Masr'), findsNothing);
      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      expect(find.text('Jordanian channels'), findsOneWidget);
      if (tv) {
        final title = find.descendant(
          of: find.widgetWithText(LiveStationRow, 'Roya TV'),
          matching: find.text('Roya TV'),
        );
        final focus = Focus.of(tester.element(title));
        focus.requestFocus();
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus, isNot(same(focus)));
        expect(played, isNull);
        await tester.tap(find.byTooltip('Versions for Roya TV'));
        await tester.pumpAndSettle();
        expect(find.text('1080p'), findsOneWidget);
        expect(find.text('HD'), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
      } else {
        await tester.tap(find.widgetWithText(LiveStationRow, 'Roya TV'));
        await tester.pumpAndSettle();
        expect(
          played?.items
              .firstWhere((item) => item.title == 'Roya TV')
              .liveVersion,
          '1080p',
        );
        expect(
          played?.items.where((item) => item.title == 'Roya TV'),
          hasLength(1),
        );
        router.pop();
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('TV Guide'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Evening news'), findsOneWidget);
      if (!tv) expect(find.textContaining('Next ·'), findsOneWidget);
      expect(find.text('Schedule unavailable'), findsWidgets);
      await snapshot('guide');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      container.dispose();
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(db.close);
      if (!tv) debugDefaultTargetPlatformOverride = null;
    });
  }
}

class _FixtureRegion extends LiveRegionPreference {
  @override
  Future<LiveRegion> build() async => LiveRegion.jordan;
}

class _TvOverride extends FormFactorOverride {
  @override
  FormFactor build() => FormFactor.tv;
}
