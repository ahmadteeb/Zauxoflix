import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/core/router/app_router.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/providers.dart';
import 'package:zauxoflix/features/live/live_tv_screen.dart';
import 'package:zauxoflix/main.dart';

import 'support/auth_test_overrides.dart';

/// Counts add/dispose events for [nowPlayingProvider] specifically.
final class _NowPlayingSpy extends ProviderObserver {
  int added = 0;
  int disposed = 0;

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    if (identical(context.provider, nowPlayingProvider)) added++;
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    if (identical(context.provider, nowPlayingProvider)) disposed++;
  }
}

void main() {
  testWidgets('nowPlaying poll stops when the Live tab is hidden', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.insertSource(
      SourcesCompanion.insert(
        name: 'test',
        serverUrl: 'http://127.0.0.1:1',
        username: 'u',
        password: 'p',
      ),
    );

    final spy = _NowPlayingSpy();
    final container = ProviderContainer(
      observers: [spy],
      overrides: [
        databaseProvider.overrideWithValue(db),
        // Replace the real 60s-polling body with one that stays open without a
        // timer, so the test can only pass on the provider's autoDispose
        // config and the screen's visibility gate — not on timer quirks.
        nowPlayingProvider.overrideWith((ref) async* {
          yield const <String, EpgProgramme>{};
          await Completer<void>().future;
        }),
        authenticatedOverride,
      ],
    );

    Future<void> settle() async {
      await tester.pump();
      await tester.pump();
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

    final router = container.read(appRouterProvider);

    // Enter Live: the screen is visible, so it subscribes and the provider
    // starts.
    router.go('/live');
    await settle();
    expect(find.byType(LiveTvScreen), findsOneWidget);
    expect(spy.added, greaterThanOrEqualTo(1));
    final disposedWhileVisible = spy.disposed;

    // Switch away: the branch stays mounted (IndexedStack) but TickerMode is
    // disabled, so the screen drops its subscription and the autoDispose
    // provider tears down — the poll no longer runs in the background.
    router.go('/home');
    await settle();
    expect(spy.disposed, greaterThan(disposedWhileVisible));

    // Returning restarts it.
    final addedWhileHidden = spy.added;
    router.go('/live');
    await settle();
    expect(spy.added, greaterThan(addedWhileHidden));

    // Tear down inside the test body (see escape_back_test) so drift's
    // stream-close timers fire before the pending-timer invariant runs.
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump(const Duration(seconds: 1));
  });
}
