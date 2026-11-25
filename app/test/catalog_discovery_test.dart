import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/data/db/app_database.dart';

void main() {
  late AppDatabase db;
  late int source;
  Future<int> addSource() => db.insertSource(
    SourcesCompanion.insert(
      name: 'Fixture',
      serverUrl: '',
      username: '',
      password: '',
    ),
  );
  LiveChannelsCompanion channel(
    int id,
    String name, {
    int? number,
    String? category,
  }) => LiveChannelsCompanion.insert(
    sourceId: source,
    streamId: id,
    name: name,
    channelNumber: Value(number),
    categoryId: Value(category),
  );
  Future<List<int>> collection(
    LiveCollection view, {
    String? category,
    String query = '',
  }) async =>
      (await db
              .watchChannelCollection(
                source,
                view,
                categoryId: category,
                query: query,
              )
              .first)
          .map((c) => c.streamId)
          .toList();
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    source = await addSource();
  });
  tearDown(() => db.close());
  test(
    'bilingual titles, typed aliases, numeric channels, and literal wildcards are ranked before the limit',
    () async {
      await db.replaceLiveChannels(source, [
        channel(1, 'KMBC', number: 1),
        channel(2, 'AR | MBC 1 HD', number: 2),
        channel(3, 'MBC', number: 9),
        channel(4, 'aljazeera', number: 12),
        channel(5, 'News 12', number: 13),
        channel(6, '100%_News'),
      ]);
      await db.replaceMovies(source, [
        MoviesCompanion.insert(
          sourceId: source,
          streamId: 15,
          name: 'John Wick 2',
        ),
      ]);
      await db.replaceSeries(source, [
        SeriesItemsCompanion.insert(
          sourceId: source,
          seriesId: 25,
          name: 'بَاب الـحَارَة',
        ),
      ]);
      for (final query in ['MBC', 'إم بي سي', 'امبيسي']) {
        expect(
          (await db.searchLiveChannels(
            source,
            query,
            limit: 3,
          )).map((c) => c.streamId),
          [3, 2, 1],
        );
      }
      expect((await db.searchLiveChannels(source, '١٢')).first.streamId, 4);
      expect(
        (await db.searchLiveChannels(source, 'الجزيرة')).single.streamId,
        4,
      );
      expect((await db.searchLiveChannels(source, '%_')).single.streamId, 6);
      expect((await db.searchMovies(source, 'جون ويك ٢')).single.streamId, 15);
      expect(
        (await db.searchSeries(source, 'Bab Al Hara')).single.seriesId,
        25,
      );
      expect((await db.searchSeries(source, 'باب الحارة')).single.seriesId, 25);
      expect(await db.searchMovies(source, 'غير موجود'), isEmpty);
    },
  );
  test(
    'recent and favorites are scoped, ordered, deduplicated and joined to the surviving channel',
    () async {
      final other = await addSource();
      final lineup = [
        for (var i = 1; i <= 34; i++)
          channel(i, 'MBC $i', category: i.isEven ? 'even' : 'odd'),
      ];
      await db.replaceLiveChannels(source, lineup);
      await db.replaceLiveChannels(other, [
        LiveChannelsCompanion.insert(
          sourceId: other,
          streamId: 1,
          name: 'Other',
        ),
      ]);
      await db.addFavorite(
        sourceId: source,
        kind: CatalogKind.live,
        itemId: 2,
        name: 'Old name',
      );
      await db.addFavorite(
        sourceId: source,
        kind: CatalogKind.vod,
        itemId: 3,
        name: 'Movie',
      );
      await db.recordLivePlayback(other, 1);
      for (var i = 1; i <= 34; i++) {
        await db.recordLivePlayback(source, i);
      }
      await db.recordLivePlayback(source, 8);
      await db.recordLivePlayback(source, 999);
      expect(await collection(LiveCollection.recent), [
        8,
        for (var i = 34; i >= 5; i--)
          if (i != 8) i,
      ]);
      expect(
        await collection(
          LiveCollection.recent,
          category: 'odd',
          query: 'ام بي سي 33',
        ),
        [33],
      );
      expect(await collection(LiveCollection.favorites), [2]);
      await db.replaceLiveChannels(source, [
        channel(2, 'Renamed'),
        channel(8, 'Other name'),
      ]);
      expect(await collection(LiveCollection.recent), [8]);
      expect(
        (await db
                .watchChannelCollection(source, LiveCollection.favorites)
                .first)
            .single
            .name,
        'Renamed',
      );
      await db.removeFavorite(source, CatalogKind.live, 2);
      expect(await collection(LiveCollection.favorites), isEmpty);
      await db.deleteSource(source);
      expect((await db.select(db.recentChannels).get()).single.sourceId, other);
    },
  );
}
