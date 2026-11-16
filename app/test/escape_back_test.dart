import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/core/router/app_router.dart';
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
}
