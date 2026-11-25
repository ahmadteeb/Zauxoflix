import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zauxoflix/features/shell/app_shell.dart';
import 'package:zauxoflix/features/shell/destinations.dart';
import 'package:zauxoflix/core/models/media_item.dart';
import 'package:zauxoflix/core/responsive/form_factor.dart';
import 'package:zauxoflix/features/home/widgets/content_rail.dart';
import 'package:zauxoflix/features/home/widgets/hero_banner.dart';
import 'package:zauxoflix/features/home/widgets/home_remote_navigation.dart';
import 'package:zauxoflix/features/home/widgets/poster_card.dart';
import 'package:zauxoflix/features/shell/top_nav_bar.dart';

void main() {
  testWidgets(
    'TV remote enters the first card, remembers each row and keeps the focused card visible',
    (t) async {
      t.view.physicalSize = const Size(1280, 720);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      String? opened;
      final previousTvBuild = kTvBuild;
      kTvBuild = true;
      addTearDown(() => kTvBuild = previousTvBuild);
      Widget rail(String title, int count, {bool wide = false}) => ContentRail(
        title: title,
        formFactor: FormFactor.tv,
        wide: wide,
        items: List.generate(
          count,
          (i) => MediaItem(title: '$title $i', continueWatching: wide),
        ),
        onSelect: (item) => opened = item.title,
      );
      final featured = HeroBanner(
        item: const MediaItem(title: 'Featured'),
        formFactor: FormFactor.tv,
        onDetails: () => opened = 'Details',
        onToggleMyList: () => opened = 'My List',
      );
      final home = HomeRemoteNavigation(
        child: ListView(
          children: [
            HomeFocusRow(featured: true, child: featured),
            rail('Continue Watching', 16, wide: true),
            rail('Empty', 0),
            rail('Recommended movies', 22),
            rail('Recommended series', 8),
            for (var i = 0; i < 4; i++) rail('Later row $i', 8),
          ],
        ),
      );
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => AppShell(navigationShell: shell),
            branches: [
              for (final d in appDestinations)
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: d.path,
                      builder: (_, _) =>
                          d.path == '/home' ? home : const SizedBox(),
                    ),
                  ],
                ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await t.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      Future<void> key(LogicalKeyboardKey k) async {
        await t.sendKeyEvent(k);
        await t.pump();
        await t.pump(const Duration(milliseconds: 220));
      }

      String? focusedCard() => FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<PosterCard>()
          ?.item
          .title;
      await t.pump();
      await t.pump();
      await key(LogicalKeyboardKey.enter);
      expect(opened, 'Details');
      await key(LogicalKeyboardKey.arrowRight);
      await key(LogicalKeyboardKey.enter);
      expect(opened, 'My List');
      await key(LogicalKeyboardKey.arrowDown);
      expect(focusedCard(), 'Continue Watching 0');
      await key(LogicalKeyboardKey.arrowLeft);
      expect(focusedCard(), 'Continue Watching 0');
      for (var i = 1; i < 11; i++) {
        await key(LogicalKeyboardKey.arrowRight);
        expect(focusedCard(), 'Continue Watching $i');
        final bounds = FocusManager.instance.primaryFocus!.rect;
        expect(bounds.left, greaterThanOrEqualTo(40));
        expect(bounds.right, lessThanOrEqualTo(1240));
      }
      await key(LogicalKeyboardKey.select);
      expect(opened, 'Continue Watching 10');
      await key(LogicalKeyboardKey.arrowDown);
      expect(focusedCard(), 'Recommended movies 0');
      await key(LogicalKeyboardKey.arrowRight);
      await key(LogicalKeyboardKey.arrowDown);
      expect(focusedCard(), 'Recommended series 0');
      expect(
        FocusManager.instance.primaryFocus!.rect.top,
        greaterThanOrEqualTo(kTopNavHeight),
      );
      for (var i = 0; i < 4; i++) {
        await key(LogicalKeyboardKey.arrowDown);
        expect(focusedCard(), 'Later row $i 0');
      }
      await key(LogicalKeyboardKey.arrowDown);
      expect(focusedCard(), 'Later row 3 0');
      for (var i = 0; i < 4; i++) {
        await key(LogicalKeyboardKey.arrowUp);
      }
      expect(focusedCard(), 'Recommended series 0');
      await key(LogicalKeyboardKey.arrowUp);
      expect(focusedCard(), 'Recommended movies 1');
      await key(LogicalKeyboardKey.arrowUp);
      expect(focusedCard(), 'Continue Watching 10');
      await key(LogicalKeyboardKey.arrowUp);
      await key(LogicalKeyboardKey.arrowUp);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'nav:Home');
      await key(LogicalKeyboardKey.arrowDown);
      await key(LogicalKeyboardKey.arrowDown);
      expect(focusedCard(), 'Continue Watching 10');
      // Jump to the nav as a pointer or shortcut can do while a later rail is visible.
      await key(LogicalKeyboardKey.arrowDown);
      final nav = FocusManager.instance.rootScope.descendants.firstWhere(
        (n) => n.debugLabel == 'nav:Home',
      );
      nav.requestFocus();
      await t.pump();
      await key(LogicalKeyboardKey.arrowDown);
      await key(LogicalKeyboardKey.enter);
      expect(opened, 'Details');
      expect(t.getTopLeft(find.byType(HeroBanner)).dy, closeTo(0, 1));
      expect(t.takeException(), isNull);
    },
  );

  for (final (form, size) in [
    (FormFactor.mobile, const Size(390, 844)),
    (FormFactor.desktop, const Size(1280, 800)),
    (FormFactor.tv, const Size(1920, 1080)),
  ]) {
    testWidgets('hero and resume row share a leading edge at ${size.width}', (
      t,
    ) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [
                  HeroBanner(
                    item: const MediaItem(
                      title: 'The Night Manager',
                      subtitle: 'Because you saved Slow Horses',
                    ),
                    formFactor: form,
                    headlineLabel: 'Top pick for you',
                    onDetails: () {},
                  ),
                  ContentRail(
                    title: 'Continue Watching',
                    items: const [
                      MediaItem(title: 'Slow Horses', continueWatching: true),
                    ],
                    wide: true,
                    formFactor: form,
                    onSelect: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await t.pump();
      final left = t.getTopLeft(find.text('Continue Watching')).dx;
      expect(t.getTopLeft(find.text('The Night Manager')).dx, closeTo(left, 1));
      expect(t.getTopLeft(find.byType(PosterCard)).dx, closeTo(left, 1));
      if (form.isTv) {
        expect(
          t.getBottomLeft(find.byType(PosterCard)).dy,
          lessThanOrEqualTo(size.height),
        );
      }
      expect(t.takeException(), isNull);
    });
  }
}
