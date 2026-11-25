import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/core/models/media_item.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/discovery/discovery_repository.dart';
import 'package:zauxoflix/data/discovery/home_recommendations.dart';
import 'package:zauxoflix/data/providers.dart';
import 'package:zauxoflix/data/resume/resume_service.dart';

void main() {
  for (final kind in [CatalogKind.vod, CatalogKind.series]) {
    test(
      '$kind Home uses saved, active and finished library titles offline',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            discoveryClientProvider.overrideWithValue(null),
          ],
        );
        addTearDown(() async {
          container.dispose();
          await db.close();
        });
        final source = await db.insertSource(
          SourcesCompanion.insert(
            name: 'Local',
            serverUrl: '',
            username: '',
            password: '',
          ),
        );
        final other = await db.insertSource(
          SourcesCompanion.insert(
            name: 'Other',
            serverUrl: '',
            username: '',
            password: '',
          ),
        );
        final series = kind == CatalogKind.series;
        for (final id in [source, other]) {
          await db.replaceCategories(id, kind, [
            CategoriesCompanion.insert(
              sourceId: id,
              kind: kind,
              categoryId: 'drama',
              name: 'Drama',
            ),
          ]);
          if (series) {
            await db.replaceSeries(id, [
              for (var i = 1; i <= 4; i++)
                SeriesItemsCompanion.insert(
                  sourceId: id,
                  seriesId: i,
                  name: '$id Show $i',
                  categoryId: const Value('drama'),
                ),
            ]);
          } else {
            await db.replaceMovies(id, [
              for (var i = 1; i <= 4; i++)
                MoviesCompanion.insert(
                  sourceId: id,
                  streamId: i,
                  name: '$id Film $i',
                  categoryId: const Value('drama'),
                ),
            ]);
          }
        }
        await db.addFavorite(
          sourceId: source,
          kind: kind,
          itemId: 1,
          name: 'One',
        );
        final resume = ResumeService(db, source);
        Future<void> report(int id, int minutes) => resume.report(
          kind: series ? WatchKind.episode : WatchKind.movie,
          itemId: series ? 900 + id : id,
          seriesId: series ? id : null,
          title: 'Two',
          position: Duration(minutes: minutes),
          duration: const Duration(minutes: 100),
        );
        await report(2, 20);
        if (series) {
          await resume.completeEpisode(
            seriesId: 3,
            episodeId: 903,
            title: 'Three',
            finishedSubtitle: 'S1 E1',
            finishedDuration: 6000,
            nextId: 904,
          );
        } else {
          await report(3, 96);
        }
        for (final reason in RecommendationReason.values) {
          container.listen(homePicksProvider((source, reason)), (_, _) {});
        }
        container.listen(
          homePicksProvider((other, RecommendationReason.watched)),
          (_, _) {},
        );
        final result = await Future.wait([
          for (final reason in RecommendationReason.values)
            container.read(homePicksProvider((source, reason)).future),
        ]);
        final titles = result.map((r) => r!.title);
        final type = series ? 'Show' : 'Film';
        expect(titles, [
          'Because you saved $source $type 1',
          'Because you’re watching $source $type 2',
          'Because you watched ${series ? "an episode of " : ""}$source $type 3',
        ]);
        for (final rail in result) {
          expect(rail!.items.map((i) => (i.title, i.id, i.type)), [
            ('$source $type 4', 4, series ? MediaType.series : MediaType.movie),
          ]);
        }
        expect(
          await container.read(
            homePicksProvider((other, RecommendationReason.watched)).future,
          ),
          isNull,
        );
        final watched = (await db.select(db.watchedTitles).get()).single;
        expect((watched.kind, watched.itemId), (kind, 3));
        if (series) {
          // Older installs kept only the queued successor after finishing an episode.
          await db.delete(db.watchedTitles).go();
          await container.pump();
          final legacyContainer = ProviderContainer(
            overrides: [
              databaseProvider.overrideWithValue(db),
              discoveryClientProvider.overrideWithValue(null),
            ],
          );
          try {
            final p = homePicksProvider((source, RecommendationReason.watched));
            legacyContainer.listen(p, (_, _) {});
            expect((await legacyContainer.read(p.future))?.seed, (
              CatalogKind.series,
              3,
            ));
          } finally {
            legacyContainer.dispose();
          }
        }
        await db.clearSyncedData();
        expect(await db.select(db.watchedTitles).get(), isEmpty);
      },
    );
  }
}
