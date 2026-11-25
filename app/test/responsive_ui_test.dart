import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:zauxoflix/data/backend/auth_models.dart';
import 'package:zauxoflix/features/settings/account_dialogs.dart';
import 'package:zauxoflix/features/settings/pair_tv_dialog.dart';
import 'package:zauxoflix/features/settings/iptv_info_dialog.dart';
import 'package:zauxoflix/features/auth/forgot_password_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:zauxoflix/core/models/media_item.dart';
import 'package:zauxoflix/core/responsive/form_factor.dart';
import 'package:zauxoflix/core/theme/app_theme.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/providers.dart';
import 'package:zauxoflix/data/releases/release_repository.dart';
import 'package:zauxoflix/features/auth/login_screen.dart';
import 'package:zauxoflix/features/auth/register_screen.dart';
import 'package:zauxoflix/features/browse/browse_screen.dart';
import 'package:zauxoflix/features/details/details_widgets.dart';
import 'package:zauxoflix/features/downloads/downloads_screen.dart';
import 'package:zauxoflix/features/guide/epg_grid_screen.dart';
import 'package:zauxoflix/features/home/home_screen.dart';
import 'package:zauxoflix/features/home/widgets/hero_banner.dart';
import 'package:zauxoflix/features/live/live_tv_screen.dart';
import 'package:zauxoflix/features/search/search_screen.dart';
import 'package:zauxoflix/features/settings/settings_screen.dart';
import 'package:zauxoflix/features/shell/top_nav_bar.dart';
import 'package:zauxoflix/features/shell/destinations.dart';
import 'package:zauxoflix/features/shell/mobile_nav_bar.dart';
import 'package:zauxoflix/features/source_setup/source_setup_screen.dart';
import 'package:zauxoflix/main.dart';
import 'support/auth_test_overrides.dart';

void main() {
  testWidgets('phone hero actions align and keep large labels readable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final taps = <String>[];
    for (final (width, scale) in [(384.0, 1.0), (320.0, 1.0), (375.0, 2.0)]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 900),
              textScaler: TextScaler.linear(scale),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: HeroBanner(
                  item: const MediaItem(title: 'Last Meal', subtitle: ''),
                  formFactor: FormFactor.mobile,
                  playLabel: 'Resume',
                  onPlay: () => taps.add('Resume'),
                  onDetails: () => taps.add('Details'),
                  onToggleMyList: () => taps.add('My List'),
                ),
              ),
            ),
          ),
        ),
      );
      final targets = ['Resume', 'Details', 'My List']
          .map(
            (label) => find
                .ancestor(
                  of: find.text(label),
                  matching: find.byType(GestureDetector),
                )
                .first,
          )
          .toList();
      final bounds = targets.map(tester.getRect).toList();
      if (scale == 1) expect(bounds[0].top, bounds[2].top);
      expect(bounds[0].height, greaterThanOrEqualTo(48));
      for (var i = 1; i < bounds.length; i++) {
        expect(bounds[i].width, closeTo(bounds.first.width, 1));
        expect(bounds[i].height, bounds.first.height);
        if (scale == 1) {
          expect(bounds[i].left - bounds[i - 1].right, greaterThanOrEqualTo(6));
        } else {
          expect(bounds[i].left, bounds.first.left);
          expect(bounds[i].top - bounds[i - 1].bottom, greaterThanOrEqualTo(6));
        }
      }
      if (scale > 1) {
        final label = tester.renderObject<RenderParagraph>(find.text('Resume'));
        expect(
          label.getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 6),
          ),
          hasLength(1),
        );
      }
      for (final target in targets) {
        await tester.tap(target);
      }
      expect(taps, ['Resume', 'Details', 'My List']);
      taps.clear();
      expect(tester.takeException(), isNull);
    }
  });

  const cases = [
    (Size(360, 640), 1.3, FormFactor.mobile),
    (Size(600, 960), 1.2, FormFactor.mobile),
    (Size(1024, 600), 1.5, FormFactor.tablet),
    (Size(320, 720), 1.0, FormFactor.mobile),
    (Size(375, 812), 2.0, FormFactor.mobile),
    (Size(844, 390), 1.4, FormFactor.mobile),
    (Size(768, 1024), 1.2, FormFactor.tablet),
    (Size(1440, 900), 1.0, FormFactor.desktop),
    (Size(1920, 1080), 1.0, FormFactor.tv),
  ];
  for (final (size, scale, form) in cases) {
    testWidgets(
      'screens fit ${size.width}x${size.height}, text $scale, ${form.name}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        await db.insertSource(
          SourcesCompanion.insert(
            name: 'Test playlist',
            serverUrl: 'https://provider.example/list.m3u?token=private',
            username: '',
            password: '',
            sourceType: const Value(SourceType.m3u),
          ),
        );
        await db.replaceMovies(1, [
          MoviesCompanion.insert(
            sourceId: 1,
            streamId: 1,
            name:
                'A very long movie title that needs to fit on a small phone screen',
          ),
        ]);
        final now = DateTime.now();
        await db.replaceSeries(1, [
          SeriesItemsCompanion.insert(
            sourceId: 1,
            seriesId: 9,
            name: 'القضاء · Family Secrets',
          ),
        ]);
        await db.replaceLiveChannels(1, [
          LiveChannelsCompanion.insert(
            sourceId: 1,
            streamId: 3,
            name: 'قناة الأخبار · News',
            epgChannelId: const Value('guide-news'),
            channelNumber: const Value(3),
          ),
        ]);
        await db
            .into(db.epgProgrammes)
            .insert(
              EpgProgrammesCompanion.insert(
                sourceId: 1,
                channelId: 'guide-news',
                startAt: now.subtract(const Duration(minutes: 20)),
                endAt: now.add(const Duration(hours: 1)),
                title: 'Evening news',
                description: const Value('The latest reports.'),
              ),
            );
        await db.upsertDownload(
          DownloadsCompanion.insert(
            sourceId: 1,
            kind: WatchKind.episode,
            itemId: 13,
            seriesId: const Value(9),
            title: 'القضاء · Family Secrets',
            subtitle: const Value('S1 E4 — Circle Narrowing'),
            filePath: 'fixture.mkv',
            status: DownloadStatus.done,
            createdAt: now,
          ),
        );
        await db.savePosition(
          PlaybackPositionsCompanion.insert(
            sourceId: 1,
            kind: WatchKind.episode,
            itemId: 13,
            seriesId: const Value(9),
            title: 'القضاء · Family Secrets',
            subtitle: const Value('S1 E4 — Circle Narrowing'),
            positionSecs: 0,
            durationSecs: 0,
            updatedAt: now,
          ),
        );
        final container = ProviderContainer(
          overrides: [
            authenticatedOverride,
            databaseProvider.overrideWithValue(db),
            formFactorOverrideProvider.overrideWith(() => FixedForm(form)),
            packageInfoProvider.overrideWith(
              (ref) async => PackageInfo(
                appName: 'Zauxoflix',
                packageName: 'app',
                version: '1.0.0',
                buildNumber: '1',
              ),
            ),
          ],
        );
        final sourceSubscription = container.listen(
          activeSourceProvider,
          (_, next) {},
        );
        await container.read(activeSourceProvider.future);
        final nodes = List.generate(
          appDestinations.length,
          (index) => FocusNode(),
        );
        final screens = <String, Widget>{
          'home': const HomeScreen(),
          'live': const LiveTvScreen(),
          'movies': const BrowseScreen.movies(),
          'series': const BrowseScreen.series(),
          'search': const SearchScreen(),
          'settings': const SettingsScreen(),
          'guide': const EpgGridScreen(),
          'downloads': const DownloadsScreen(),
          'source setup': const SourceSetupScreen(),
          'login': const LoginScreen(),
          'registration': const RegisterScreen(),
          'details': DetailsScaffold(
            title: 'A long movie or series title with many words',
            onPlay: () {},
            plot: 'A description that wraps across multiple lines.',
            favorite: false,
            onToggleFavorite: () {},
          ),
          'hero': SingleChildScrollView(
            child: HeroBanner(
              item: const MediaItem(
                title:
                    'A very long featured title that wraps across several lines',
                subtitle:
                    'A description of this movie to check large text readability.',
              ),
              formFactor: form,
              playLabel: 'Resume',
              onPlay: () {},
              onDetails: () {},
              onToggleMyList: () {},
            ),
          ),
          'IPTV dialog': DialogLauncher(
            (context) => showIptvInfoDialog(
              context,
              container.read(activeSourceProvider).value!,
            ),
          ),
          'profile dialog': DialogLauncher(
            (context) => showEditProfileDialog(
              context,
              const BackendUser(id: 'test', email: 'viewer@example.com'),
            ),
          ),
          'password dialog': DialogLauncher(showChangePasswordDialog),
          'pair TV dialog': DialogLauncher(showPairTvDialog),
          'recovery dialog': DialogLauncher(
            (context) => showForgotPasswordDialog(context),
          ),
          'top navigation': TopNavBar(
            selectedIndex: 0,
            onSelect: (_) {},
            itemFocusNodes: nodes,
          ),
        };
        for (final entry in screens.entries) {
          final router = GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, state) => Scaffold(body: entry.value),
              ),
              GoRoute(
                path: '/home',
                builder: (_, state) => const Scaffold(body: HomeScreen()),
              ),
            ],
          );
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp.router(
                routerConfig: router,
                theme: AppTheme.dark,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true,
                    viewInsets:
                        entry.key.endsWith('dialog') &&
                            form == FormFactor.mobile
                        ? EdgeInsets.only(bottom: size.height < 500 ? 120 : 250)
                        : EdgeInsets.zero,
                  ),
                  child: child!,
                ),
              ),
            ),
          );
          for (var i = 0; i < 6; i++) {
            await tester.pump(const Duration(milliseconds: 40));
          }
          if (entry.key.endsWith('dialog')) {
            await tester.tap(find.text('Open dialog'));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          }
          if (entry.key == 'recovery dialog') {
            expect(find.text('I already have a code'), findsNothing);
            expect(find.text('Send code'), findsOneWidget);
          }
          expect(
            tester.takeException(),
            isNull,
            reason: '${entry.key} at $size text $scale',
          );
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          router.dispose();
        }
        for (final node in nodes) {
          node.dispose();
        }
        sourceSubscription.close();
        container.dispose();
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(db.close);
      },
    );
  }
  testWidgets('top navigation buttons are keyboard operable', (tester) async {
    final nodes = List.generate(appDestinations.length, (index) => FocusNode());
    var selected = -1;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeSourceProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: TopNavBar(
              selectedIndex: 0,
              onSelect: (index) => selected = index,
              itemFocusNodes: nodes,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Downloads'));
    expect(selected, appDestinations.indexWhere((d) => d.path == '/downloads'));
    nodes[0].requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(selected, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(selected, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    for (final node in nodes) {
      node.dispose();
    }
  });
  testWidgets(
    'mobile header actions and Settings navigation work across screen sizes',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.insertSource(
        SourcesCompanion.insert(
          name: 'Test',
          serverUrl: 'https://provider.example/list.m3u',
          username: '',
          password: '',
          sourceType: const Value(SourceType.m3u),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authenticatedOverride,
          databaseProvider.overrideWithValue(db),
          packageInfoProvider.overrideWith(
            (ref) async => PackageInfo(
              appName: 'Zauxoflix',
              packageName: 'app',
              version: '1.0.0',
              buildNumber: '1',
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ZauxoflixApp(),
        ),
      );
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final dock = find.byType(MobileNavBar);
      final dockHighlight = find.descendant(
        of: dock,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).gradient ==
                  AppColors.selectionGradient,
        ),
      );
      expect(dockHighlight, findsOneWidget);
      final homeList = find
          .descendant(
            of: find.byType(HomeScreen),
            matching: find.byType(ListView),
          )
          .first;
      expect(
        tester.getBottomLeft(homeList).dy,
        greaterThan(tester.getTopLeft(dock).dy),
      );
      expect(
        (tester.widget<ListView>(homeList).padding! as EdgeInsets).bottom,
        greaterThan(tester.getSize(dock).height),
      );
      final enabledBlur = find.byWidgetPredicate(
        (widget) => widget is BackdropFilter && widget.enabled,
      );
      expect(enabledBlur, findsOneWidget);
      await tester.tap(find.byTooltip('Search'));
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(enabledBlur, findsNothing);
      await tester.tap(find.byTooltip('Downloads'));
      await tester.pumpAndSettle();
      expect(find.byType(DownloadsScreen), findsOneWidget);
      expect(dock, findsOneWidget);
      expect(tester.widget<MobileNavBar>(dock).selectedIndex, 5);
      expect(find.text('More'), findsNothing);
      for (final label in ['Home', 'Live TV', 'Movies', 'Series', 'Settings']) {
        final destination = find.descendant(
          of: dock,
          matching: find.text(label),
        );
        expect(destination, findsOneWidget);
        final button = find.ancestor(
          of: destination,
          matching: find.byType(TextButton),
        );
        expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      }
      await tester.tap(
        find.descendant(of: dock, matching: find.text('Movies')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BrowseScreen), findsOneWidget);
      expect(dockHighlight, findsOneWidget);
      await tester.tap(
        find.descendant(of: dock, matching: find.text('Settings')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(
        tester.widget<MobileNavBar>(dock).selectedIndex,
        appDestinations.indexWhere((d) => d.path == '/settings'),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.widgetWithText(TextButton, 'Playlist'));
      await tester.pumpAndSettle();
      final change = find.text('Change playlist');
      await tester.ensureVisible(change);
      await tester.tap(change);
      await tester.pumpAndSettle();
      expect(find.byType(SourceSetupScreen), findsOneWidget);
      final cancel = find.text('Cancel');
      await tester.ensureVisible(cancel);
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(SourceSetupScreen), findsNothing);
      for (final (size, phone) in [
        (const Size(320, 640), true),
        (const Size(844, 390), true),
        (const Size(1024, 600), false),
        (const Size(1440, 900), false),
        (const Size(600, 960), true),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(find.byType(SettingsScreen), findsOneWidget);
        expect(
          find.byType(MobileNavBar),
          phone ? findsOneWidget : findsNothing,
        );
        expect(find.byType(TopNavBar), phone ? findsNothing : findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'Shell resize to $size');
      }

      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(db.close);
    },
  );
}

class FixedForm extends FormFactorOverride {
  FixedForm(this.form);
  final FormFactor form;
  @override
  FormFactor? build() => form;
}

class DialogLauncher extends StatelessWidget {
  const DialogLauncher(this.open, {super.key});
  final Future<dynamic> Function(BuildContext) open;
  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      onPressed: () => open(context),
      child: const Text('Open dialog'),
    ),
  );
}
