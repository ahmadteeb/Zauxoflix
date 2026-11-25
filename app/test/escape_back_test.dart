import 'package:go_router/go_router.dart';
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/core/router/app_router.dart';
import 'package:zauxoflix/core/responsive/form_factor.dart';
import 'package:zauxoflix/core/tv/tv_back_button.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/providers.dart';
import 'package:zauxoflix/features/details/movie_details_screen.dart';
import 'package:zauxoflix/features/details/series_details_screen.dart';
import 'package:zauxoflix/features/home/home_screen.dart';
import 'package:zauxoflix/main.dart';

import 'support/auth_test_overrides.dart';

void main() {
  testWidgets('Escape pops pushed routes but not shell tabs', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.insertSource(
      SourcesCompanion.insert(
        name: 'test',
        serverUrl: 'http://127.0.0.1:1',
        username: 'u',
        password: 'p',
      ),
    );

    await db.replaceMovies(1, [
      MoviesCompanion.insert(sourceId: 1, streamId: 42, name: 'Card movie'),
    ]);
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        authenticatedOverride,
      ],
    );

    Future<void> settle() async {
      await tester.pump();
      await tester.pump();
      // Desktop Material page transitions run up to ~600ms.
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ZauxoflixApp(),
      ),
    );
    await settle();
    expect(find.byType(HomeScreen), findsOneWidget);

    final router = container.read(appRouterProvider);

    final openPreview = find.byTooltip('Preview Card movie').first;
    await tester.ensureVisible(openPreview);
    await tester.tap(openPreview);
    await settle();
    await tester.tap(find.text('View details').last);
    await settle();
    expect(router.state.uri.path, '/movie/42');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle();
    expect(find.byType(HomeScreen), findsOneWidget);

    unawaited(router.push('/movie/1'));
    await settle();
    expect(find.byType(MovieDetailsScreen), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle();
    expect(find.byType(MovieDetailsScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);

    unawaited(router.push('/series/1'));
    await settle();
    expect(find.byType(SeriesDetailsScreen), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle();
    expect(find.byType(SeriesDetailsScreen), findsNothing);

    // At a shell branch root Escape must be a no-op, not exit or throw.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle();
    expect(find.byType(HomeScreen), findsOneWidget);

    // Tear down inside the test body so drift's stream-close timers and the
    // EPG minute-refresh timer fire before the pending-timer invariant runs.
    // The in-memory db is deliberately NOT closed: drift's close() deadlocks
    // under FakeAsync and throws under runAsync while stream queries unwind.
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    // A bare pump() does not elapse fake time, so drift's zero-duration
    // stream-close timers would stay pending and trip the invariant.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('TV remote shortcut and on-screen Back share one history', (
    tester,
  ) async {
    final initialTv = kTvBuild;
    kTvBuild = true;
    addTearDown(() => kTvBuild = initialTv);
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const Text('Home')),
        GoRoute(
          path: '/movies',
          builder: (context, _) => Scaffold(
            body: TvBackButton(
              onPressed: () =>
                  Actions.invoke(context, const NavigateBackIntent()),
            ),
          ),
        ),
        GoRoute(
          path: '/detail',
          builder: (_, _) => const Scaffold(body: Text('Details')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appRouterProvider.overrideWithValue(router),
          authenticatedOverride,
        ],
        child: const ZauxoflixApp(),
      ),
    );
    await tester.pumpAndSettle();
    router.go('/movies');
    await tester.pumpAndSettle();
    unawaited(router.push('/detail'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(
      LogicalKeyboardKey.colorF0Red,
      physicalKey: PhysicalKeyboardKey.f1,
    );
    await tester.pumpAndSettle();
    expect(find.byType(TvBackButton), findsOneWidget);
    await tester.tap(find.byType(TvBackButton));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'TV Back closes a dialog and details before retracing visited tabs',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const Text('Home'),
          ),
          GoRoute(
            path: '/live',
            builder: (context, state) => const Text('Live'),
          ),
          GoRoute(
            path: '/movies',
            builder: (context, state) => const Text('Movies'),
          ),
          GoRoute(
            path: '/detail',
            builder: (context, state) => const Text('Details'),
          ),
        ],
      );
      addTearDown(router.dispose);
      final back = TvBackButtonDispatcher(router);
      addTearDown(back.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: RouterConfig(
            routeInformationProvider: router.routeInformationProvider,
            routeInformationParser: router.routeInformationParser,
            routerDelegate: router.routerDelegate,
            backButtonDispatcher: back,
          ),
        ),
      );
      router.go('/movies');
      await tester.pumpAndSettle();
      router.go('/live');
      await tester.pumpAndSettle();
      unawaited(router.push('/detail'));
      await tester.pumpAndSettle();
      unawaited(
        showDialog<void>(
          context: tester.element(find.text('Details')),
          builder: (_) => const AlertDialog(title: Text('Cast')),
        ),
      );
      await tester.pumpAndSettle();
      expect(await back.didPopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Cast'), findsNothing);
      expect(find.text('Details'), findsOneWidget);
      expect(await back.didPopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Live'), findsOneWidget);
      expect(await back.didPopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Movies'), findsOneWidget);
      expect(await back.didPopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(await back.didPopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    },
  );

  testWidgets(
    'LG asks to exit only at Home and waits for explicit confirmation',
    (tester) async {
      final previousTv = kTvBuild;
      kTvBuild = true;
      addTearDown(() => kTvBuild = previousTv);
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          for (final path in ['/home', '/movies', '/detail'])
            GoRoute(
              path: path,
              builder: (_, _) => Scaffold(body: Text(path)),
            ),
        ],
      );
      final back = TvBackButtonDispatcher(router, confirmExitAtHome: true);
      int exits = 0;
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'SystemNavigator.pop') exits++;
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      addTearDown(router.dispose);
      addTearDown(back.dispose);

      Future<void> pressLgKey(int keyCode, int scanCode) async {
        // The embedder sends both ordinary and unmapped keys on its GLFW channel.
        for (final type in ['keydown', 'keyup']) {
          await messenger.handlePlatformMessage(
            'flutter/keyevent',
            const JSONMessageCodec().encodeMessage({
              'keymap': 'linux',
              'toolkit': 'glfw',
              'keyCode': keyCode,
              'scanCode': scanCode,
              'modifiers': 0,
              'type': type,
            }),
            null,
          );
        }
      }

      Future<void> settleBack() async {
        await pressLgKey(412, 420);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 200));
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appRouterProvider.overrideWithValue(router),
            tvBackDispatcherProvider.overrideWithValue(back),
            authenticatedOverride,
          ],
          child: const ZauxoflixApp(),
        ),
      );
      await tester.pumpAndSettle();
      router.go('/movies');
      await tester.pumpAndSettle();
      unawaited(router.push('/detail'));
      await tester.pumpAndSettle();
      unawaited(
        showDialog<void>(
          context: tester.element(find.text('/detail')),
          builder: (_) => const AlertDialog(title: Text('Cast')),
        ),
      );
      await tester.pumpAndSettle();
      await settleBack();
      expect(find.text('/detail'), findsOneWidget);
      await settleBack();
      expect(find.text('/movies'), findsOneWidget);
      await settleBack();
      expect(find.text('/home'), findsOneWidget);
      expect(find.text('Exit Zauxoflix?'), findsNothing);

      // Two near-simultaneous deliveries of one physical press.
      await back.didPopRoute();
      await back.didPopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Exit Zauxoflix?'), findsOneWidget);
      expect(Focus.of(tester.element(find.text('Stay'))).hasFocus, isTrue);
      await tester.pump(const Duration(milliseconds: 200));
      await settleBack();
      expect(find.text('Exit Zauxoflix?'), findsNothing);
      expect(exits, 0);

      await settleBack();
      await pressLgKey(257, 36); // OK
      await tester.pumpAndSettle();
      expect(find.text('Exit Zauxoflix?'), findsNothing);
      expect(exits, 0);

      await settleBack();
      await pressLgKey(262, 114); // Right
      await tester.pumpAndSettle();
      await pressLgKey(257, 36);
      await tester.pumpAndSettle();
      expect(exits, 1);
    },
  );
}
