import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:zauxoflix/data/xtream/xtream_models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/resume/resume_service.dart';

void main() {
  late AppDatabase db;
  late int sourceId;
  late ResumeService resume;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    sourceId = await db.insertSource(
      SourcesCompanion.insert(
        name: 'Test',
        serverUrl: 'http://server',
        username: 'u',
        password: 'p',
      ),
    );
    resume = ResumeService(db, sourceId);
  });

  tearDown(() => db.close());

  group('ResumeService', () {
    test(
      'caught-up series returns when a later episode or season arrives',
      () async {
        const finale = XtreamEpisode(
          id: 88,
          title: 'Finale',
          season: 1,
          episodeNum: 12,
        );
        const next = XtreamEpisode(
          id: 92,
          title: 'A new chapter',
          season: 2,
          episodeNum: 1,
        );
        await resume.completeEpisode(
          seriesId: 7,
          episodeId: 88,
          title: 'Series',
          finishedSubtitle: 'S1 E12 — Finale',
          finishedDuration: 2000,
          imageUrl: 'https://example.test/poster',
        );
        expect(await db.watchContinueWatching(sourceId).first, isEmpty);
        final checks = <int, DateTime>{};
        var requests = 0;
        final reopened = ResumeService(db, sourceId);
        await reopened.refreshCaughtUp(
          (_) async {
            requests++;
            return const XtreamSeriesInfo(
              seasons: {
                1: [finale],
              },
            );
          },
          checks,
          active: () => true,
        );
        expect(await db.watchContinueWatching(sourceId).first, isEmpty);
        Future<XtreamSeriesInfo> updated(int _) async {
          requests++;
          return const XtreamSeriesInfo(
            seasons: {
              2: [next],
              1: [finale],
            },
          );
        }

        await reopened.refreshCaughtUp(updated, checks, active: () => true);
        expect(requests, 1);
        checks[7] = DateTime.now().subtract(const Duration(hours: 7));
        await reopened.refreshCaughtUp(updated, checks, active: () => true);
        final row = (await db.watchContinueWatching(sourceId).first).single;
        expect(
          (row.itemId, row.positionSecs, row.subtitle),
          (92, 0, 'S2 E1 — A new chapter'),
        );
        expect(row.imageUrl, 'https://example.test/poster');
        await reopened.report(
          kind: WatchKind.episode,
          itemId: 92,
          seriesId: 7,
          title: 'Series',
          position: const Duration(seconds: 4),
          duration: const Duration(minutes: 40),
        );
        expect(
          (await db.watchContinueWatching(sourceId).first).single.itemId,
          92,
        );
        expect(await db.caughtUpEpisodes(sourceId), isEmpty);
      },
    );

    test(
      'new same-season episodes return after a catalog outage and ID change',
      () async {
        await resume.completeEpisode(
          seriesId: 7,
          episodeId: 111,
          title: 'Show',
          finishedSubtitle: 'S1 E7 — Seven',
          finishedDuration: 1800,
        );
        final checks = <int, DateTime>{};
        await resume.refreshCaughtUp(
          (_) async => throw StateError('offline'),
          checks,
          active: () => true,
        );
        expect(await db.watchContinueWatching(sourceId).first, isEmpty);
        checks[7] = DateTime.now().subtract(const Duration(hours: 7));
        await resume.refreshCaughtUp(
          (_) async => const XtreamSeriesInfo(
            seasons: {
              1: [
                XtreamEpisode(
                  id: 301,
                  title: 'Seven',
                  season: 1,
                  episodeNum: 7,
                ),
                XtreamEpisode(
                  id: 302,
                  title: 'Eight',
                  season: 1,
                  episodeNum: 8,
                ),
                XtreamEpisode(id: 303, title: 'Nine', season: 1, episodeNum: 9),
              ],
            },
          ),
          checks,
          active: () => true,
        );
        final next = (await db.watchContinueWatching(sourceId).first).single;
        expect(
          (next.itemId, next.subtitle, next.positionSecs),
          (302, 'S1 E8 — Eight', 0),
        );
      },
    );

    test(
      'manual removal while checking for a new episode stays removed',
      () async {
        await resume.completeEpisode(
          seriesId: 7,
          episodeId: 88,
          title: 'Series',
          finishedSubtitle: 'S1 E1 — Pilot',
          finishedDuration: 1200,
        );
        final started = Completer<void>(),
            response = Completer<XtreamSeriesInfo>();
        final checking = resume.refreshCaughtUp(
          (_) {
            started.complete();
            return response.future;
          },
          {},
          active: () => true,
        );
        await started.future;
        await db.deletePositionsForSeries(sourceId, 7);
        response.complete(
          const XtreamSeriesInfo(
            seasons: {
              1: [
                XtreamEpisode(id: 93, title: 'New', season: 1, episodeNum: 2),
              ],
            },
          ),
        );
        await checking;
        expect(await db.watchContinueWatching(sourceId).first, isEmpty);
      },
    );

    test(
      'finishing an episode preserves an existing resume point for its successor',
      () async {
        await resume.report(
          kind: WatchKind.episode,
          itemId: 13,
          seriesId: 7,
          title: 'Series',
          subtitle: 'S2 E1 — Premiere',
          position: const Duration(minutes: 5),
          duration: const Duration(minutes: 30),
        );
        await resume.completeEpisode(
          seriesId: 7,
          episodeId: 12,
          title: 'Series',
          nextId: 13,
          subtitle: 'S2 E1 — Premiere',
          finishedSubtitle: 'S1 E12 — Finale',
          finishedDuration: 1800,
        );
        final row = (await db.watchContinueWatching(sourceId).first).single;
        expect(
          (row.itemId, row.positionSecs, row.durationSecs),
          (13, 300, 1800),
        );
      },
    );

    test('saves a mid-playback position', () async {
      await resume.report(
        kind: WatchKind.movie,
        itemId: 42,
        title: 'Some Film',
        imageUrl: 'http://img/42.jpg',
        containerExtension: 'mkv',
        position: const Duration(minutes: 20),
        duration: const Duration(minutes: 90),
      );
      final position = await db
          .watchPosition(sourceId, WatchKind.movie, 42)
          .first;
      expect(position, isNotNull);
      expect(position!.positionSecs, 20 * 60);
      expect(position.durationSecs, 90 * 60);
      expect(position.title, 'Some Film');
    });

    test('ignores very short media and barely-started playback', () async {
      await resume.report(
        kind: WatchKind.movie,
        itemId: 1,
        title: 'Clip',
        position: const Duration(minutes: 1),
        duration: const Duration(minutes: 2),
      );
      await resume.report(
        kind: WatchKind.movie,
        itemId: 2,
        title: 'Film',
        position: const Duration(seconds: 5),
        duration: const Duration(minutes: 90),
      );
      expect(await db.watchContinueWatching(sourceId).first, isEmpty);
    });

    test('finishing a movie removes its resume point', () async {
      await resume.report(
        kind: WatchKind.movie,
        itemId: 42,
        title: 'Some Film',
        position: const Duration(minutes: 20),
        duration: const Duration(minutes: 90),
      );
      await resume.report(
        kind: WatchKind.movie,
        itemId: 42,
        title: 'Some Film',
        position: const Duration(minutes: 89),
        duration: const Duration(minutes: 90),
      );
      expect(
        await db.watchPosition(sourceId, WatchKind.movie, 42).first,
        isNull,
      );
    });

    test('series resume tracks the most recent episode', () async {
      for (final (episodeId, minutes) in [(101, 10), (102, 15)]) {
        await resume.report(
          kind: WatchKind.episode,
          itemId: episodeId,
          seriesId: 7,
          title: 'Show',
          subtitle: 'E$episodeId',
          position: Duration(minutes: minutes),
          duration: const Duration(minutes: 45),
        );
      }
      // Second report is newer (same wall-clock second is possible, so
      // bump 101 again to make ordering deterministic via updatedAt).
      await db.savePosition(
        PlaybackPositionsCompanion.insert(
          sourceId: sourceId,
          kind: WatchKind.episode,
          itemId: 102,
          seriesId: const Value(7),
          title: 'Show',
          positionSecs: 15 * 60,
          durationSecs: 45 * 60,
          updatedAt: DateTime.now().add(const Duration(seconds: 5)),
        ),
      );
      final positions = await db.watchSeriesPositions(sourceId, 7).first;
      expect(positions.first.itemId, 102);
      expect(positions, hasLength(2));
    });

    test(
      'continue watching collapses a series to its latest episode',
      () async {
        final t0 = DateTime(2026, 1, 1);
        Future<void> save(
          WatchKind kind,
          int itemId,
          int? seriesId,
          DateTime at,
        ) => db.savePosition(
          PlaybackPositionsCompanion.insert(
            sourceId: sourceId,
            kind: kind,
            itemId: itemId,
            seriesId: Value(seriesId),
            title: 'T$itemId',
            positionSecs: 600,
            durationSecs: 2700,
            updatedAt: at,
          ),
        );
        await save(WatchKind.episode, 101, 7, t0);
        await save(
          WatchKind.episode,
          102,
          7,
          t0.add(const Duration(minutes: 1)),
        );
        await save(
          WatchKind.movie,
          42,
          null,
          t0.add(const Duration(minutes: 2)),
        );

        final rows = await db.watchContinueWatching(sourceId).first;
        expect(rows, hasLength(2));
        expect(rows[0].itemId, 42);
        expect(rows[1].itemId, 102);
      },
    );
  });

  group('favorites', () {
    test('add, watch and remove', () async {
      final isFavorite = db.watchIsFavorite(sourceId, CatalogKind.vod, 42);
      expect(await isFavorite.first, isFalse);

      await db.addFavorite(
        sourceId: sourceId,
        kind: CatalogKind.vod,
        itemId: 42,
        name: 'Some Film',
      );
      expect(await isFavorite.first, isTrue);
      // Same channel id under a different kind stays independent.
      expect(
        await db.watchIsFavorite(sourceId, CatalogKind.live, 42).first,
        isFalse,
      );

      final favorites = await db.watchFavorites(sourceId).first;
      expect(favorites.single.name, 'Some Film');

      await db.removeFavorite(sourceId, CatalogKind.vod, 42);
      expect(await isFavorite.first, isFalse);
    });

    test('deleteSource clears favorites and positions', () async {
      await db.addFavorite(
        sourceId: sourceId,
        kind: CatalogKind.live,
        itemId: 1,
        name: 'Channel',
      );
      await resume.report(
        kind: WatchKind.movie,
        itemId: 42,
        title: 'Some Film',
        position: const Duration(minutes: 20),
        duration: const Duration(minutes: 90),
      );
      await db.deleteSource(sourceId);
      expect(await db.select(db.favorites).get(), isEmpty);
      expect(await db.select(db.playbackPositions).get(), isEmpty);
    });
  });

  group('search', () {
    test('matches names case-insensitively per kind', () async {
      await db.replaceLiveChannels(sourceId, [
        LiveChannelsCompanion.insert(
          sourceId: sourceId,
          streamId: 1,
          name: 'BBC News',
        ),
        LiveChannelsCompanion.insert(
          sourceId: sourceId,
          streamId: 2,
          name: 'CNN',
        ),
      ]);
      await db.replaceMovies(sourceId, [
        MoviesCompanion.insert(
          sourceId: sourceId,
          streamId: 10,
          name: 'News of the World',
        ),
      ]);
      await db.replaceSeries(sourceId, [
        SeriesItemsCompanion.insert(
          sourceId: sourceId,
          seriesId: 20,
          name: 'Breaking News',
        ),
      ]);

      expect(
        (await db.searchLiveChannels(sourceId, 'news')).single.name,
        'BBC News',
      );
      expect((await db.searchMovies(sourceId, 'NEWS')).single.streamId, 10);
      expect((await db.searchSeries(sourceId, 'news')).single.seriesId, 20);
      expect(await db.searchLiveChannels(sourceId, 'zzz'), isEmpty);
    });
  });
}
