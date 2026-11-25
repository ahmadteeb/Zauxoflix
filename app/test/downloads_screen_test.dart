import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zauxoflix/core/theme/app_theme.dart';
import 'package:zauxoflix/data/backend/remote_models.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/downloads/download_manager.dart';
import 'package:zauxoflix/data/providers.dart';
import 'package:zauxoflix/features/downloads/downloads_screen.dart';
import 'package:zauxoflix/features/downloads/download_nav_icon.dart';
import 'package:zauxoflix/features/player/player_screen.dart';
import 'package:zauxoflix/features/remote/cast_session.dart';
import 'package:zauxoflix/features/shell/top_nav_bar.dart';
import 'package:zauxoflix/main.dart';

import 'support/auth_test_overrides.dart';

void main() {
  testWidgets(
    'Downloads clears the shell and confirms removal before deleting',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final temp = Directory.systemTemp.createTempSync('downloads-ui-');
      addTearDown(() => temp.deleteSync(recursive: true));
      final file = File('${temp.path}/episode.mp4')
        ..writeAsStringSync('fixture');
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.insertSource(
        SourcesCompanion.insert(
          name: 'Downloads fixture',
          serverUrl: 'https://example.test',
          username: '',
          password: '',
        ),
      );
      await db.upsertDownload(
        DownloadsCompanion.insert(
          sourceId: 1,
          kind: WatchKind.episode,
          itemId: 2,
          seriesId: const Value(3),
          title: 'Fixture series',
          subtitle: const Value('S1 E1 — Pilot'),
          filePath: file.path,
          totalBytes: const Value(5 * 1024 * 1024),
          status: DownloadStatus.done,
          createdAt: DateTime.now(),
        ),
      );
      await db.upsertDownload(
        DownloadsCompanion.insert(
          sourceId: 1,
          kind: WatchKind.movie,
          itemId: 4,
          title: 'Interrupted movie',
          filePath: '${temp.path}/interrupted.mp4',
          status: DownloadStatus.downloading,
          createdAt: DateTime.now(),
        ),
      );
      final controlled = _ControlledDownloadManager();
      final container = ProviderContainer(
        overrides: [
          authenticatedOverride,
          databaseProvider.overrideWithValue(db),
          downloadManagerProvider.overrideWith(() => controlled),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ZauxoflixApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Downloads'));
      await tester.pumpAndSettle();

      final screen = find.byType(DownloadsScreen);
      final heading = find.descendant(
        of: screen,
        matching: find.text('Downloads'),
      );
      expect(
        tester.getTopLeft(heading).dy,
        greaterThan(tester.getBottomLeft(find.byType(TopNavBar)).dy),
      );
      expect(find.text('Download interrupted'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Resume'), findsOneWidget);
      expect(find.text('5.0 MB on this device'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      controlled.update({
        (1, WatchKind.movie, 4): const DownloadProgress(
          DownloadPhase.downloading,
          receivedBytes: 40,
          totalBytes: 100,
        ),
      });
      await tester.pump();
      final ring = find.descendant(
        of: find.byType(DownloadNavIcon),
        matching: find.byType(CircularProgressIndicator),
      );
      expect(tester.widget<CircularProgressIndicator>(ring).value, .4);
      controlled.update({});
      await tester.pump();
      expect(ring, findsNothing);
      expect(find.text('S1 E1 — Pilot'), findsOneWidget);
      await tester.tap(find.text('Fixture series'));
      await tester.pumpAndSettle();
      expect(find.text('S1 E1 — Pilot'), findsNothing);
      await tester.tap(find.text('Fixture series'));
      await tester.pumpAndSettle();
      final removeEpisode = find.byTooltip('Remove download').last;
      await tester.tap(removeEpisode);
      await tester.pumpAndSettle();
      expect(find.text('Remove download?'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Remove download?'), findsNothing);
      expect(file.existsSync(), isTrue);

      await tester.tap(removeEpisode);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
      // The confirmation completes in the widget clock, while the file uses
      // real I/O. Let both advance until the database reflects the removal.
      for (var attempt = 0; attempt < 40; attempt++) {
        await tester.pump(const Duration(milliseconds: 30));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        if (find.text('Fixture series').evaluate().isEmpty) break;
      }
      await tester.pumpAndSettle();
      expect(file.existsSync(), isFalse);
      expect(find.text('Fixture series'), findsNothing);
      expect(find.text('On this device'), findsNothing);
      expect(find.text('1'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(db.close);
    },
  );

  testWidgets(
    'Play offline opens the local file even with an active cast target',
    (tester) async {
      final temp = Directory.systemTemp.createTempSync('downloads-play-');
      addTearDown(() => temp.deleteSync(recursive: true));
      final file = File('${temp.path}/movie.mp4')..writeAsStringSync('fixture');
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.insertSource(
        SourcesCompanion.insert(
          name: 'Fixture',
          serverUrl: '',
          username: '',
          password: '',
        ),
      );
      await db.upsertDownload(
        DownloadsCompanion.insert(
          sourceId: 1,
          kind: WatchKind.movie,
          itemId: 2,
          title: 'Saved movie',
          filePath: file.path,
          status: DownloadStatus.done,
          createdAt: DateTime.now(),
        ),
      );
      await db.savePosition(
        PlaybackPositionsCompanion.insert(
          sourceId: 1,
          kind: WatchKind.movie,
          itemId: 2,
          title: 'Saved movie',
          positionSecs: 45,
          durationSecs: 240,
          updatedAt: DateTime.now(),
        ),
      );
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      container
          .read(castTargetProvider.notifier)
          .set(
            const RemoteDevice(deviceId: 'fixture-cast-device', online: true),
          );
      PlayerArgs? opened;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: DownloadsScreen()),
          ),
          GoRoute(
            path: '/player',
            builder: (_, state) {
              opened = state.extra! as PlayerArgs;
              return const SizedBox.shrink();
            },
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Play offline'));
      await tester.pumpAndSettle();
      for (var attempt = 0; opened == null && attempt < 20; attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await tester.pump(const Duration(milliseconds: 30));
      }
      expect(tester.takeException(), isNull);
      expect(opened?.items.single.url, file.path);
      expect(opened?.items.single.startAt, const Duration(seconds: 45));

      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      container.dispose();
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(db.close);
    },
  );

  testWidgets('bulk cleanup keeps unwatched downloads and watch history', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final temp = Directory.systemTemp.createTempSync('download-cleanup-');
    addTearDown(() => temp.deleteSync(recursive: true));
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.insertSource(
      SourcesCompanion.insert(
        name: 'Fixture',
        serverUrl: '',
        username: '',
        password: '',
      ),
    );
    final files = {
      for (final id in [1, 2])
        id: File('${temp.path}/episode-$id.mp4')..writeAsStringSync('fixture'),
    };
    for (final entry in files.entries) {
      await db.upsertDownload(
        DownloadsCompanion.insert(
          sourceId: 1,
          kind: WatchKind.episode,
          itemId: entry.key,
          title: 'Episode ${entry.key}',
          filePath: entry.value.path,
          status: DownloadStatus.done,
          totalBytes: const Value(1024),
          createdAt: DateTime.now(),
        ),
      );
    }
    await db.recordWatchedEpisode(1, 1);
    final container = ProviderContainer(
      overrides: [
        authenticatedOverride,
        databaseProvider.overrideWithValue(db),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ZauxoflixApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Downloads'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove watched episodes'));
    await tester.pumpAndSettle();
    expect(find.textContaining('This can free up 1.0 KB'), findsOneWidget);
    expect(files[1]!.existsSync(), isTrue);
    await tester.tap(find.text('Remove 1'));
    for (var attempt = 0; attempt < 40; attempt++) {
      await tester.pump(const Duration(milliseconds: 30));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      if (!files[1]!.existsSync() &&
          find.text('Episode 1').evaluate().isEmpty) {
        break;
      }
    }
    expect(files[1]!.existsSync(), isFalse);
    expect(files[2]!.existsSync(), isTrue);
    expect(await db.select(db.watchedEpisodes).get(), hasLength(1));
    expect(find.text('Episode 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  });
}

class _ControlledDownloadManager extends DownloadManager {
  void update(Map<DownloadKey, DownloadProgress> progress) => state = progress;
}
