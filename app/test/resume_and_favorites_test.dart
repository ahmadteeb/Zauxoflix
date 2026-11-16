import 'package:drift/drift.dart' show Value;
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
