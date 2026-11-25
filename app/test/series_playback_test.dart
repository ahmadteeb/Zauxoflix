import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zauxoflix/core/theme/app_theme.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/providers.dart';
import 'package:zauxoflix/data/xtream/xtream_api.dart';
import 'package:zauxoflix/data/xtream/xtream_models.dart';
import 'package:zauxoflix/features/details/series_details_screen.dart';
import 'package:zauxoflix/features/player/player_screen.dart';

class _SeriesApi extends XtreamApi {
  _SeriesApi()
    : super(
        XtreamCredentials(
          serverUrl: 'https://example.test',
          username: '',
          password: '',
        ),
      );
  final requests = <Completer<XtreamSeriesInfo>>[];
  @override
  Future<XtreamSeriesInfo> seriesInfo(int seriesId) {
    final request = Completer<XtreamSeriesInfo>();
    requests.add(request);
    return request.future;
  }
}

void main() {
  for (final size in [const Size(390, 844), const Size(1920, 1080)]) {
    testWidgets(
      'series details retries and resumes the chosen row at ${size.width}',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final source = await db.insertSource(
          SourcesCompanion.insert(
            name: 'Playlist',
            serverUrl: 'https://example.test',
            username: '',
            password: '',
          ),
        );
        await db.replaceSeries(source, [
          SeriesItemsCompanion.insert(
            sourceId: source,
            seriesId: 7,
            name: 'Series',
          ),
        ]);
        for (final (episode, seconds) in [(21, 65), (22, 140)]) {
          await db.savePosition(
            PlaybackPositionsCompanion.insert(
              sourceId: source,
              kind: WatchKind.episode,
              itemId: episode,
              seriesId: const Value(7),
              title: 'Series',
              positionSecs: seconds,
              durationSecs: 800,
              updatedAt: DateTime.utc(2025, 1, episode),
            ),
          );
        }
        final api = _SeriesApi();
        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            xtreamApiProvider.overrideWithValue(api),
          ],
        );
        PlayerArgs? opened;
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const SeriesDetailsScreen(seriesId: 7),
            ),
            GoRoute(
              path: '/player',
              builder: (_, state) {
                opened = state.extra! as PlayerArgs;
                return const Scaffold(body: Text('Playing'));
              },
            ),
          ],
        );
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Future<void> frames() async {
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 700));
          await tester.pump();
        }

        try {
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp.router(
                theme: AppTheme.dark,
                routerConfig: router,
              ),
            ),
          );
          await frames();
          expect(api.requests, hasLength(1));
          api.requests.single.completeError(
            StateError('temporary provider error'),
          );
          await frames();
          expect(
            find.text('No episodes listed for this series.'),
            findsNothing,
          );
          final retry = find.widgetWithText(TextButton, 'Retry');
          await tester.ensureVisible(retry);
          Focus.of(tester.element(find.text('Retry'))).requestFocus();
          await frames();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await frames();
          expect(api.requests, hasLength(2));
          expect(retry, findsNothing);
          api.requests.last.complete(
            const XtreamSeriesInfo(
              seasons: {
                1: [
                  XtreamEpisode(
                    id: 21,
                    title: 'First',
                    season: 1,
                    episodeNum: 1,
                  ),
                  XtreamEpisode(
                    id: 22,
                    title: 'Second',
                    season: 1,
                    episodeNum: 2,
                  ),
                  XtreamEpisode(
                    id: 23,
                    title: 'Third',
                    season: 1,
                    episodeNum: 3,
                  ),
                ],
              },
            ),
          );
          await frames();
          expect(find.text('Resume S1 E2'), findsOneWidget);
          for (final (name, id, seconds) in [
            ('First', 21, 65),
            ('Third', 23, 0),
          ]) {
            final row = find.text(name);
            await tester.ensureVisible(row);
            await tester.tap(row);
            await frames();
            expect(find.text('Playing'), findsOneWidget);
            final args = opened!;
            final item = args.items[args.initialIndex];
            expect(args.items.length, 3);
            expect(item.identity?.episodeId, '$id');
            expect(
              item.startAt,
              seconds == 0 ? null : Duration(seconds: seconds),
            );
            router.pop();
            await frames();
          }
          expect(api.requests, hasLength(2));
        } finally {
          await tester.pumpWidget(const SizedBox());
          router.dispose();
          container.dispose();
          final closed = db.close();
          await tester.pump(const Duration(seconds: 1));
          await closed;
        }
      },
    );
  }
}
