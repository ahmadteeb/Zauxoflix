import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:zauxoflix/data/db/app_database.dart';

void main() {
  test(
    'sign-in can reopen an upgraded library reported as version 8 without resetting viewer data',
    () async {
      final dir = await Directory.systemTemp.createTemp('zauxoflix_reopen');
      final file = File('${dir.path}/existing.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      try {
        final id = await db.insertSource(
          SourcesCompanion.insert(
            name: 'Existing library',
            serverUrl: '',
            username: '',
            password: '',
          ),
        );
        await db.replaceMovies(id, [
          MoviesCompanion.insert(
            sourceId: id,
            streamId: 7,
            name: 'Existing Film',
            releaseYear: const Value(1994),
            externalId: const Value('tt0111161'),
          ),
        ]);
        await db.addFavorite(
          sourceId: id,
          kind: CatalogKind.vod,
          itemId: 7,
          name: 'Existing Film',
        );
        await db.customStatement(
          "INSERT INTO recommendation_snapshots(source_id,slot,day,payload) VALUES(?, 'home.v1','2026-11-23','{}')",
          [id],
        );
        await db.customStatement(
          "INSERT INTO watched_titles(source_id,kind,item_id,watched_at) VALUES(?,'series',3,99)",
          [id],
        );
        await db.customStatement(
          "UPDATE movies SET release_year=1994 WHERE source_id=? AND stream_id=7",
          [id],
        );
        await db.customStatement('PRAGMA user_version=8');
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase(file));
        expect((await db.watchActiveSource().first)?.id, id);
        expect((await db.getMovie(id, 7))?.releaseYear, 1994);
        expect((await db.getMovie(id, 7))?.externalId, 'tt0111161');
        expect((await db.allFavorites(id)).single.itemId, 7);
        expect((await db.select(db.watchedTitles).get()).single.itemId, 3);
        expect(
          (await db.select(db.recommendationSnapshots).get()).single.slot,
          'home.v1',
        );
        final version = await db
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.read<int>('user_version'), db.schemaVersion);
      } finally {
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );

  test(
    'new and upgraded caches use the browse indexes and keep tied and unnumbered items in order',
    () async {
      final dir = await Directory.systemTemp.createTemp('zauxoflix_index_test');
      final file = File('${dir.path}/catalog.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      try {
        final id = await db.insertSource(
          SourcesCompanion.insert(
            name: 'p',
            serverUrl: '',
            username: '',
            password: '',
          ),
        );
        final recent = DateTime.utc(2026);
        await db.addFavorite(
          sourceId: id,
          kind: CatalogKind.vod,
          itemId: 1,
          name: 'Same',
        );
        await db.savePosition(
          PlaybackPositionsCompanion.insert(
            sourceId: id,
            kind: WatchKind.movie,
            itemId: 1,
            title: 'Same',
            positionSecs: 23,
            durationSecs: 99,
            updatedAt: recent,
          ),
        );
        await db.replaceMovies(id, [
          for (final n in [3, 1, 2])
            MoviesCompanion.insert(
              sourceId: id,
              streamId: n,
              name: 'Same',
              addedAt: n == 1 ? const Value(null) : Value(recent),
            ),
        ]);
        await db.replaceLiveChannels(id, [
          for (final n in [3, 1, 2])
            LiveChannelsCompanion.insert(
              sourceId: id,
              streamId: n,
              name: 'Same',
              channelNumber: n == 1 ? const Value(null) : const Value(1),
            ),
        ]);
        const plans = {
          'movie_source_recent':
              'movies WHERE source_id=1 ORDER BY added_at DESC NULLS LAST, name, stream_id LIMIT 20',
          'series_source_recent':
              'series_items WHERE source_id=1 ORDER BY last_modified_at DESC NULLS LAST, name, series_id LIMIT 20',
          'live_source_number':
              'live_channels WHERE source_id=1 ORDER BY channel_number NULLS LAST, name, stream_id LIMIT 20',
        };
        for (final upgrade in [false, true]) {
          if (upgrade) {
            await db.customStatement('DROP TABLE watched_titles');
            await db.customStatement('DROP TABLE recent_channels');
            for (final table in ['live_channels', 'movies', 'series_items']) {
              await db.customStatement(
                'ALTER TABLE $table DROP COLUMN search_name',
              );
            }
            for (final index in plans.keys) {
              await db.customStatement('DROP INDEX $index');
            }
            await db.customStatement('DROP TABLE catalog_validators');
            await db.customStatement(
              'ALTER TABLE sources DROP COLUMN discovered_epg_url',
            );
            await db.customStatement('DROP TABLE discovery_entries');
            for (final table in ['movies', 'series_items']) {
              await db.customStatement('DROP INDEX ${table}_discovery_name');
              await db.customStatement('DROP INDEX ${table}_external_id');
              for (final column in [
                'match_name',
                'release_year',
                'external_id',
                'rating_scale',
              ]) {
                await db.customStatement(
                  'ALTER TABLE $table DROP COLUMN $column',
                );
              }
            }
            await db.customStatement('PRAGMA user_version = 6');
            await db.customStatement(
              "CREATE TRIGGER interrupt_search BEFORE UPDATE ON movies BEGIN SELECT RAISE(ABORT,'interrupted backfill'); END",
            );
            await db.close();
            db = AppDatabase.forTesting(NativeDatabase(file));
            await expectLater(
              db.searchMovies(id, 'same'),
              throwsA(isA<SqliteException>()),
            );
            await db.close();
            final original = sqlite3.open(file.path);
            try {
              expect(
                original.select('PRAGMA user_version').single.values.first,
                6,
              );
              expect(
                original
                    .select('PRAGMA table_info(movies)')
                    .map((c) => c['name']),
                isNot(contains('search_name')),
              );
              original.execute('DROP TRIGGER interrupt_search');
            } finally {
              original.dispose();
            }
            db = AppDatabase.forTesting(NativeDatabase(file));
          }
          expect((await db.searchMovies(id, 'same')).length, 3);
          expect((await db.getMovie(id, 1))?.matchName, 'same');
          expect((await db.allFavorites(id)).single.itemId, 1);
          expect(
            (await db.watchPosition(id, WatchKind.movie, 1).first)
                ?.positionSecs,
            23,
          );
          for (final entry in plans.entries) {
            final details =
                (await db
                        .customSelect(
                          'EXPLAIN QUERY PLAN SELECT * FROM ${entry.value}',
                        )
                        .get())
                    .map((row) => row.read<String>('detail'))
                    .join(' ');
            expect(details, contains(entry.key));
            expect(details, isNot(contains('TEMP B-TREE')));
          }
          expect((await db.watchMovies(id).first).map((e) => e.streamId), [
            2,
            3,
            1,
          ]);
          expect(
            (await db.watchLiveChannels(id).first).map((e) => e.streamId),
            [2, 3, 1],
          );
        }
      } finally {
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
