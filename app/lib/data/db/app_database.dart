import '../discovery/title_identity.dart';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:sqlite3/open.dart' as sqlite;

import '../../core/app_paths.dart';
import '../catalog_search.dart';
import '../../core/app_platform.dart';

part 'app_database.g.dart';

/// Use the TV's SQLite runtime library in both the app and Drift isolates.
void configureWebOsSqlite() =>
    sqlite.open.overrideForAll(() => DynamicLibrary.open('libsqlite3.so.0'));

enum SourceType { xtream, m3u }

/// A configured playlist (Xtream account or M3U URL). Credentials live
/// locally for now; they move behind the backend once real auth lands.
/// For m3u sources [serverUrl] is the playlist URL and username/password
/// are empty.
class Sources extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get sourceType =>
      textEnum<SourceType>().withDefault(const Constant('xtream'))();
  TextColumn get serverUrl => text()();
  TextColumn get username => text()();
  TextColumn get password => text()();

  /// Optional XMLTV URL. Xtream sources fall back to their xmltv.php feed.
  TextColumn get epgUrl => text().nullable()();
  TextColumn get discoveredEpgUrl => text().nullable()();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}

enum CatalogKind { live, vod, series }

enum LiveCollection { all, recent, favorites }

enum CatalogFeed {
  liveCategories,
  movieCategories,
  seriesCategories,
  channels,
  movies,
  series,
  playlist,
}

class CatalogValidators extends Table {
  IntColumn get sourceId => integer().references(Sources, #id)();
  TextColumn get feed => textEnum<CatalogFeed>()();
  TextColumn get etag => text().nullable()();
  TextColumn get lastModified => text().nullable()();
  @override
  Set<Column> get primaryKey => {sourceId, feed};
}

/// Ordering options offered on the Movies / Series browse grids.
enum CatalogSort { recentlyAdded, nameAsc, topRated }

class Categories extends Table {
  IntColumn get sourceId => integer().references(Sources, #id)();
  TextColumn get kind => textEnum<CatalogKind>()();
  TextColumn get categoryId => text()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {sourceId, kind, categoryId};
}

@TableIndex.sql(
  'CREATE INDEX live_source_number ON live_channels (source_id, channel_number, name, stream_id)',
)
class LiveChannels extends Table {
  TextColumn get searchName => text().withDefault(const Constant(''))();
  IntColumn get sourceId => integer().references(Sources, #id)();
  IntColumn get streamId => integer()();
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get epgChannelId => text().nullable()();
  IntColumn get channelNumber => integer().nullable()();

  /// M3U entries carry their own URL; Xtream channels build it from creds.
  TextColumn get streamUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {sourceId, streamId};
}

@DataClassName('Movie')
@TableIndex.sql(
  'CREATE INDEX movie_source_recent ON movies (source_id, added_at DESC, name, stream_id)',
)
@TableIndex(name: 'movies_discovery_name', columns: {#sourceId, #matchName})
@TableIndex(name: 'movies_external_id', columns: {#sourceId, #externalId})
class Movies extends Table {
  TextColumn get matchName => text().withDefault(const Constant(''))();
  IntColumn get releaseYear => integer().nullable()();
  TextColumn get externalId => text().nullable()();
  IntColumn get ratingScale => integer().nullable()();
  TextColumn get searchName => text().withDefault(const Constant(''))();
  IntColumn get sourceId => integer().references(Sources, #id)();
  IntColumn get streamId => integer()();
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get containerExtension => text().nullable()();
  RealColumn get rating => real().nullable()();
  DateTimeColumn get addedAt => dateTime().nullable()();
  TextColumn get streamUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {sourceId, streamId};
}

@TableIndex.sql(
  'CREATE INDEX series_source_recent ON series_items (source_id, last_modified_at DESC, name, series_id)',
)
@TableIndex(
  name: 'series_items_discovery_name',
  columns: {#sourceId, #matchName},
)
@TableIndex(name: 'series_items_external_id', columns: {#sourceId, #externalId})
class SeriesItems extends Table {
  TextColumn get matchName => text().withDefault(const Constant(''))();
  IntColumn get releaseYear => integer().nullable()();
  TextColumn get externalId => text().nullable()();
  IntColumn get ratingScale => integer().nullable()();
  TextColumn get searchName => text().withDefault(const Constant(''))();
  IntColumn get sourceId => integer().references(Sources, #id)();
  IntColumn get seriesId => integer()();
  TextColumn get name => text()();
  TextColumn get cover => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get plot => text().nullable()();
  RealColumn get rating => real().nullable()();
  DateTimeColumn get lastModifiedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {sourceId, seriesId};
}

/// One EPG programme. [channelId] is the lowercased XMLTV channel id and is
/// matched against LiveChannels.epgChannelId (case-insensitively).
@DataClassName('EpgProgramme')
@TableIndex(
  name: 'epg_channel_start',
  columns: {#sourceId, #channelId, #startAt},
)
class EpgProgrammes extends Table {
  IntColumn get sourceId => integer().references(Sources, #id)();
  TextColumn get channelId => text()();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get endAt => dateTime()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
}

/// A device-local history. Replacing an entry assigns the latest sequence.
class RecentChannels extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sourceId => integer().references(Sources, #id)();
  IntColumn get streamId => integer()();
  @override
  List<Set<Column>> get uniqueKeys => [
    {sourceId, streamId},
  ];
}

class LiveViewing extends Table {
  IntColumn get sourceId => integer().references(Sources, #id)();
  TextColumn get viewer => text()();
  IntColumn get day => integer()();
  IntColumn get streamId => integer()();
  IntColumn get seconds => integer()();
  DateTimeColumn get lastWatched => dateTime()();

  @override
  Set<Column> get primaryKey => {sourceId, viewer, day, streamId};
}

class LiveTuning extends Table {
  IntColumn get sourceId => integer().references(Sources, #id)();
  TextColumn get viewer => text()();
  TextColumn get channelKey => text()();
  IntColumn get preferredStream => integer().nullable()();
  IntColumn get successfulStream => integer().nullable()();

  @override
  Set<Column> get primaryKey => {sourceId, viewer, channelKey};
}

class LiveGuideLinks extends Table {
  IntColumn get sourceId => integer().references(Sources, #id)();
  TextColumn get channelKey => text()();
  TextColumn get guideId => text()();
  BoolColumn get manual => boolean()();

  @override
  Set<Column> get primaryKey => {sourceId, channelKey};
}

/// What a playback position points at. Live channels have no resume position.
enum WatchKind { movie, episode }

/// Name/image are denormalized so the My List row renders without joins and
/// survives items disappearing from a re-synced catalog.
class Favorites extends Table {
  IntColumn get sourceId => integer().references(Sources, #id)();
  TextColumn get kind => textEnum<CatalogKind>()();
  IntColumn get itemId => integer()();
  TextColumn get name => text()();
  TextColumn get imageUrl => text().nullable()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {sourceId, kind, itemId};
}

/// Resume points. [itemId] is the movie streamId or the episode id; display
/// metadata is denormalized so Continue Watching needs no API calls.
@DataClassName('PlaybackPosition')
class PlaybackPositions extends Table {
  IntColumn get sourceId => integer().references(Sources, #id)();
  TextColumn get kind => textEnum<WatchKind>()();
  IntColumn get itemId => integer()();
  IntColumn get seriesId => integer().nullable()();
  TextColumn get title => text()();
  TextColumn get subtitle => text().withDefault(const Constant(''))();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get containerExtension => text().nullable()();
  IntColumn get positionSecs => integer()();
  IntColumn get durationSecs => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {sourceId, kind, itemId};
}

/// Last confirmed finish per movie or parent series, kept on this device.
class WatchedTitles extends Table {
  IntColumn get sourceId => integer().references(Sources, #id)();
  TextColumn get kind => textEnum<CatalogKind>()();
  IntColumn get itemId => integer()();
  DateTimeColumn get watchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {sourceId, kind, itemId};
}

class WatchedEpisodes extends Table {
  IntColumn get sourceId => integer().references(Sources, #id)();
  IntColumn get episodeId => integer()();

  @override
  Set<Column> get primaryKey => {sourceId, episodeId};
}

extension EpisodeProgress on PlaybackPosition {
  bool get isCompletedEpisode =>
      kind == WatchKind.episode &&
      seriesId != null &&
      durationSecs > 0 &&
      positionSecs >= durationSecs;
}

enum DownloadStatus { downloading, done, failed, noSpace }

/// A VOD saved to local storage for offline playback. Metadata is
/// denormalized like PlaybackPositions so the Downloads list renders
/// without joins and survives catalog re-syncs.
@DataClassName('DownloadItem')
class Downloads extends Table {
  IntColumn get sourceId => integer().references(Sources, #id)();
  TextColumn get kind => textEnum<WatchKind>()();
  IntColumn get itemId => integer()();

  /// For episodes: the parent series — keeps resume rows and cast identities
  /// correct when playing from Downloads.
  IntColumn get seriesId => integer().nullable()();
  TextColumn get title => text()();
  TextColumn get subtitle => text().withDefault(const Constant(''))();

  /// Group poster: for episodes this is the series cover (shared by the whole
  /// download group); for movies it's the movie art.
  TextColumn get imageUrl => text().nullable()();

  /// Per-episode still, so the Downloads list can show each episode's own
  /// thumbnail instead of the series cover. Null for movies.
  TextColumn get episodeImageUrl => text().nullable()();
  TextColumn get containerExtension => text().nullable()();
  TextColumn get filePath => text()();
  IntColumn get totalBytes => integer().nullable()();
  TextColumn get status => textEnum<DownloadStatus>()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {sourceId, kind, itemId};
}

/// What a tombstone marks as deleted.
enum TombstoneScope { favorite, progress }

/// Records user-initiated deletions until sync confirms the server saw them.
/// Without this, a reconcile can't tell "removed on this device while
/// offline" apart from "never had it" and would resurrect the item.
@DataClassName('SyncTombstone')
class SyncTombstones extends Table {
  IntColumn get sourceId => integer().references(Sources, #id)();
  TextColumn get scope => textEnum<TombstoneScope>()();
  TextColumn get kind => text()(); // CatalogKind.name or WatchKind.name
  IntColumn get itemId => integer()();
  IntColumn get seriesId => integer().nullable()();
  DateTimeColumn get deletedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {sourceId, scope, kind, itemId};
}

class DiscoveryEntries extends Table {
  IntColumn get sourceId => integer().references(Sources, #id)();
  TextColumn get kind => textEnum<CatalogKind>()();
  IntColumn get itemId => integer()();
  TextColumn get fingerprint => text()();
  TextColumn get payload => text()();
  DateTimeColumn get fetchedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {sourceId, kind, itemId};
}

/// Observer notified after local favorite/progress mutations so a backend
/// sync layer can mirror them upstream. Kept in the db layer (no backend
/// import) so the dependency arrow points backend → db, never the reverse.
abstract interface class SyncSink {
  void favoriteAdded(int sourceId, CatalogKind kind, int itemId);
  void favoriteRemoved(int sourceId, CatalogKind kind, int itemId);
  void progressSaved(PlaybackPositionsCompanion position);
  void progressRemoved(PlaybackPosition position);
}

// Source zero holds public charts. Positive IDs belong to one playlist.
class RecommendationSnapshots extends Table {
  IntColumn get sourceId => integer()();
  TextColumn get slot => text()();
  TextColumn get day => text()();
  TextColumn get payload => text()();
  @override
  Set<Column> get primaryKey => {sourceId, slot};
}

@DriftDatabase(
  tables: [
    Sources,
    CatalogValidators,
    Categories,
    LiveChannels,
    Movies,
    SeriesItems,
    EpgProgrammes,
    Favorites,
    RecentChannels,
    LiveViewing,
    LiveTuning,
    LiveGuideLinks,
    PlaybackPositions,
    WatchedTitles,
    WatchedEpisodes,
    SyncTombstones,
    Downloads,
    DiscoveryEntries,
    RecommendationSnapshots,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase()
    : super(
        driftDatabase(
          name: 'zauxoflix',
          native: DriftNativeOptions(
            databaseDirectory: appDataDirectory,
            isolateSetup: isWebOsPlatform ? configureWebOsSqlite : null,
          ),
        ),
      );

  AppDatabase.forTesting(super.executor);

  AppDatabase.connect(super.executor);

  AppDatabase._staging(super.executor);

  /// Attached by the sync layer at runtime; null in tests / when logged out.
  SyncSink? syncSink;
  int recommendationGeneration = 0;

  void _notify(void Function(SyncSink sink) emit) {
    final sink = syncSink;
    if (sink != null) emit(sink);
  }

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) => transaction(() async {
      if (from > to) {
        throw StateError(
          'This library was opened by a newer version of Zauxoflix.',
        );
      }
      if (from < 2) {
        await m.addColumn(sources, sources.sourceType);
        await m.addColumn(sources, sources.epgUrl);
        await m.addColumn(liveChannels, liveChannels.streamUrl);
        await m.addColumn(movies, movies.streamUrl);
        await m.createTable(epgProgrammes);
        await m.createIndex(epgChannelStart);
      }
      if (from < 3) {
        await m.createTable(favorites);
        await m.createTable(playbackPositions);
      }
      if (from < 4) {
        await m.createTable(syncTombstones);
      }
      if (from < 5) {
        await m.createTable(downloads);
      }
      if (from == 5) {
        await m.addColumn(downloads, downloads.episodeImageUrl);
      }
      if (from < 7) {
        await m.addColumn(sources, sources.discoveredEpgUrl);
        await m.createTable(catalogValidators);
        await m.createIndex(liveSourceNumber);
        await m.createIndex(movieSourceRecent);
        await m.createIndex(seriesSourceRecent);
      }
      if (from < 8) {
        await m.createTable(recentChannels);
        await m.addColumn(liveChannels, liveChannels.searchName);
        await m.addColumn(movies, movies.searchName);
        await m.addColumn(seriesItems, seriesItems.searchName);
        for (final table in [
          liveChannels.actualTableName,
          movies.actualTableName,
          seriesItems.actualTableName,
        ]) {
          int? last;
          while (true) {
            final rows = await customSelect(
              'SELECT rowid AS key, name FROM $table ${last == null ? "" : "WHERE rowid > ?"} ORDER BY rowid LIMIT 500',
              variables: [if (last != null) Variable.withInt(last)],
            ).get();
            if (rows.isEmpty) break;
            await batch((b) {
              for (final row in rows) {
                b.customStatement(
                  'UPDATE $table SET search_name = ? WHERE rowid = ?',
                  [
                    catalogSearchKey(row.read<String>('name')),
                    row.read<int>('key'),
                  ],
                );
              }
            });
            last = rows.last.read<int>('key');
          }
        }
      }
      // A previous desktop release can leave an older version marker on a
      // newer catalog. Reconcile the discovery schema before replaying DDL.
      final existing = (await customSelect(
        "SELECT name FROM sqlite_master WHERE type IN ('table','index')",
      ).get()).map((r) => r.read<String>('name')).toSet();
      if (from < 9) {
        await m.createTable(discoveryEntries);
        for (final table in <TableInfo<Table, Object?>>[movies, seriesItems]) {
          final name = table.actualTableName;
          final columns = (await customSelect(
            'PRAGMA table_info("$name")',
          ).get()).map((r) => r.read<String>('name')).toSet();
          for (final column in table.$columns.where(
            (c) => {
              'match_name',
              'release_year',
              'external_id',
              'rating_scale',
            }.contains(c.$name),
          )) {
            if (!columns.contains(column.$name)) {
              await m.addColumn(table, column);
            }
          }
          int? cursor;
          while (true) {
            final rows = await customSelect(
              "SELECT rowid AS k, name FROM $name WHERE match_name = '' ${cursor == null ? '' : 'AND rowid > ?'} ORDER BY rowid LIMIT 500",
              variables: [if (cursor != null) Variable.withInt(cursor)],
            ).get();
            if (rows.isEmpty) break;
            await batch((b) {
              for (final row in rows) {
                final title = row.read<String>('name');
                b.customStatement(
                  'UPDATE $name SET match_name=?, release_year=COALESCE(release_year, ?) WHERE rowid=?',
                  [
                    discoveryName(title),
                    splitTitle(title).year,
                    row.read<int>('k'),
                  ],
                );
              }
            });
            cursor = rows.last.read<int>('k');
          }
        }
        for (final index in [
          moviesDiscoveryName,
          moviesExternalId,
          seriesItemsDiscoveryName,
          seriesItemsExternalId,
        ]) {
          if (!existing.contains(index.entityName)) await m.createIndex(index);
        }
      }
      if (from < 10 && !existing.contains(watchedTitles.actualTableName)) {
        await m.createTable(watchedTitles);
        await customStatement("""
          INSERT INTO watched_titles (source_id, kind, item_id, watched_at)
          SELECT source_id, 'series', series_id, MAX(updated_at)
          FROM playback_positions WHERE kind='episode' AND series_id IS NOT NULL
            AND ((duration_secs > 0 AND position_secs >= duration_secs)
              OR (duration_secs=0 AND position_secs=0))
          GROUP BY source_id, series_id
        """);
      }
      if (from < 11) await m.createTable(recommendationSnapshots);
      if (from < 12) {
        await m.createTable(watchedEpisodes);
        await customStatement('''
          INSERT INTO watched_episodes (source_id, episode_id)
          SELECT source_id, item_id FROM playback_positions
          WHERE kind = 'episode' AND duration_secs > 0 AND position_secs >= duration_secs
        ''');
      }
      if (from < 13) {
        await m.createTable(liveViewing);
        await m.createTable(liveTuning);
        await m.createTable(liveGuideLinks);
      }
      // Keep the version and backfill atomic if the TV loses power at startup.
      await customStatement('PRAGMA user_version = $to');
    }),
  );

  // --- Sources ---

  Stream<Source?> watchActiveSource() =>
      (select(sources)..limit(1)).watchSingleOrNull();

  Future<int> insertSource(SourcesCompanion source) =>
      into(sources).insert(source);

  Future<void> deleteSource(int sourceId) => transaction(() async {
    recommendationGeneration++;
    await (delete(liveViewing)..where((r) => r.sourceId.equals(sourceId))).go();
    await (delete(liveTuning)..where((r) => r.sourceId.equals(sourceId))).go();
    await (delete(
      liveGuideLinks,
    )..where((r) => r.sourceId.equals(sourceId))).go();
    await (delete(
      recommendationSnapshots,
    )..where((s) => s.sourceId.equals(sourceId))).go();
    await (delete(
      discoveryEntries,
    )..where((d) => d.sourceId.equals(sourceId))).go();
    await (delete(
      watchedTitles,
    )..where((w) => w.sourceId.equals(sourceId))).go();
    await (delete(
      watchedEpisodes,
    )..where((w) => w.sourceId.equals(sourceId))).go();
    await (delete(
      recentChannels,
    )..where((c) => c.sourceId.equals(sourceId))).go();
    await (delete(
      catalogValidators,
    )..where((v) => v.sourceId.equals(sourceId))).go();
    await (delete(categories)..where((c) => c.sourceId.equals(sourceId))).go();
    await (delete(
      liveChannels,
    )..where((c) => c.sourceId.equals(sourceId))).go();
    await (delete(movies)..where((m) => m.sourceId.equals(sourceId))).go();
    await (delete(seriesItems)..where((s) => s.sourceId.equals(sourceId))).go();
    await (delete(
      epgProgrammes,
    )..where((p) => p.sourceId.equals(sourceId))).go();
    await (delete(favorites)..where((f) => f.sourceId.equals(sourceId))).go();
    await (delete(
      playbackPositions,
    )..where((p) => p.sourceId.equals(sourceId))).go();
    await (delete(
      syncTombstones,
    )..where((t) => t.sourceId.equals(sourceId))).go();
    await (delete(downloads)..where((d) => d.sourceId.equals(sourceId))).go();
    await (delete(sources)..where((s) => s.id.equals(sourceId))).go();
  });

  /// Wipes account-scoped data (favorites + resume points, across all
  /// sources) when a different account signs in on this device. Bypasses
  /// [_notify] on purpose: the purge must not be mirrored to the backend.
  Future<void> clearSyncedData() => transaction(() async {
    recommendationGeneration++;
    await delete(liveViewing).go();
    await delete(liveTuning).go();
    await (delete(
      recommendationSnapshots,
    )..where((s) => s.sourceId.isBiggerThanValue(0))).go();
    await delete(watchedTitles).go();
    await delete(watchedEpisodes).go();
    await delete(recentChannels).go();
    await delete(favorites).go();
    await delete(playbackPositions).go();
    await delete(syncTombstones).go();
  });

  /// Full local wipe on sign-out: sources, catalog, EPG, favorites and resume
  /// points all go. Server-side copies are untouched and come back on the
  /// next sign-in. Bypasses [_notify] — the purge must not sync upstream.
  Future<void> wipeAll() => transaction(() async {
    recommendationGeneration++;
    for (final table in allTables.toList().reversed) {
      await delete(table).go();
    }
  });

  Future<void> markSynced(int sourceId) =>
      (update(sources)..where((s) => s.id.equals(sourceId))).write(
        SourcesCompanion(lastSyncAt: Value(DateTime.now())),
      );

  // --- Catalog replace (called from sync, one transaction per kind) ---

  Future<void> replaceCategories(
    int sourceId,
    CatalogKind kind,
    List<CategoriesCompanion> rows,
  ) => transaction(() async {
    await (delete(
          categories,
        )..where((c) => c.sourceId.equals(sourceId) & c.kind.equalsValue(kind)))
        .go();
    await batch((b) => b.insertAll(categories, rows));
  });

  Future<void> replaceLiveChannels(
    int sourceId,
    List<LiveChannelsCompanion> rows,
  ) => transaction(() async {
    await (delete(
      liveChannels,
    )..where((c) => c.sourceId.equals(sourceId))).go();
    await batch(
      (b) => b.insertAll(
        liveChannels,
        rows
            .map(
              (r) =>
                  r.copyWith(searchName: Value(catalogSearchKey(r.name.value))),
            )
            .toList(),
      ),
    );
  });

  Future<void> replaceMovies(int sourceId, List<MoviesCompanion> rows) =>
      transaction(() async {
        await (delete(movies)..where((m) => m.sourceId.equals(sourceId))).go();
        await batch(
          (b) => b.insertAll(
            movies,
            rows
                .map(
                  (r) => r.copyWith(
                    matchName: Value(discoveryName(r.name.value)),
                    releaseYear:
                        r.releaseYear.present && r.releaseYear.value != null
                        ? r.releaseYear
                        : Value(splitTitle(r.name.value).year),
                    searchName: Value(catalogSearchKey(r.name.value)),
                  ),
                )
                .toList(),
          ),
        );
      });

  Future<void> replaceSeries(int sourceId, List<SeriesItemsCompanion> rows) =>
      transaction(() async {
        await (delete(
          seriesItems,
        )..where((s) => s.sourceId.equals(sourceId))).go();
        await batch(
          (b) => b.insertAll(
            seriesItems,
            rows
                .map(
                  (r) => r.copyWith(
                    matchName: Value(discoveryName(r.name.value)),
                    releaseYear:
                        r.releaseYear.present && r.releaseYear.value != null
                        ? r.releaseYear
                        : Value(splitTitle(r.name.value).year),
                    searchName: Value(catalogSearchKey(r.name.value)),
                  ),
                )
                .toList(),
          ),
        );
      });

  /// Stage downloads outside the active database. Only the final copy holds
  /// the writer, so browsing can continue while a feed downloads or parses.
  Future<void> publishImport(
    File file,
    Source source, {
    Map<CatalogFeed, CatalogValidatorsCompanion>? refreshedFeeds,
    String? discoveredGuide,
    Map<String, String>? automaticGuideLinks,
    Map<String, List<String>>? guideNames,
  }) => exclusively(() async {
    await customStatement('ATTACH DATABASE ? AS incoming', [file.path]);
    try {
      await transaction(() async {
        final current = await (select(
          sources,
        )..where((s) => s.id.equals(source.id))).getSingleOrNull();
        if (current == null || current.epgUrl != source.epgUrl) {
          throw StateError('Playlist changed during refresh');
        }
        if (refreshedFeeds == null) {
          await _publishTable(epgProgrammes, source.id);
          if (automaticGuideLinks != null) {
            await replaceAutomaticGuideLinks(source.id, automaticGuideLinks);
          }
          if (guideNames != null) {
            await into(recommendationSnapshots).insertOnConflictUpdate(
              RecommendationSnapshotsCompanion.insert(
                sourceId: source.id,
                slot: 'live.guide-names.v1',
                day: '1',
                payload: jsonEncode(guideNames),
              ),
            );
          }
          return;
        }
        final playlist = refreshedFeeds.containsKey(CatalogFeed.playlist);
        for (final (feed, kind) in [
          (CatalogFeed.liveCategories, CatalogKind.live),
          (CatalogFeed.movieCategories, CatalogKind.vod),
          (CatalogFeed.seriesCategories, CatalogKind.series),
        ]) {
          if (playlist || refreshedFeeds.containsKey(feed)) {
            await _publishTable(categories, source.id, category: kind);
          }
        }
        if (playlist || refreshedFeeds.containsKey(CatalogFeed.channels)) {
          await _publishTable(liveChannels, source.id);
        }
        if (playlist || refreshedFeeds.containsKey(CatalogFeed.movies)) {
          await _publishTable(movies, source.id);
        }
        if (playlist || refreshedFeeds.containsKey(CatalogFeed.series)) {
          await _publishTable(seriesItems, source.id);
        }
        await batch(
          (b) => b.insertAllOnConflictUpdate(
            catalogValidators,
            refreshedFeeds.values.toList(),
          ),
        );
        await (update(sources)..where((s) => s.id.equals(source.id))).write(
          SourcesCompanion(
            lastSyncAt: Value(DateTime.now()),
            discoveredEpgUrl: playlist
                ? Value(discoveredGuide)
                : const Value.absent(),
          ),
        );
      });
    } finally {
      await customStatement('DETACH DATABASE incoming');
    }
  });

  Future<void> _publishTable(
    TableInfo<Table, Object?> table,
    int sourceId, {
    CatalogKind? category,
  }) async {
    final name = table.actualTableName;
    // Older schemas can have a different physical column order.
    final columns = table.$columns.map((c) => c.name).join(', ');
    final filter = category == null
        ? 'source_id = ?'
        : 'source_id = ? AND kind = ?';
    await customStatement('DELETE FROM main.$name WHERE $filter', [
      sourceId,
      ?category?.name,
    ]);
    await customUpdate(
      'INSERT INTO main.$name ($columns) SELECT $columns FROM incoming.$name WHERE $filter',
      variables: [
        Variable.withInt(sourceId),
        if (category != null) Variable.withString(category.name),
      ],
      updates: {table},
    );
  }

  // --- Queries for the UI (always paged/limited; never load full catalogs) ---

  Stream<List<Category>> watchCategories(int sourceId, CatalogKind kind) =>
      (select(categories)
            ..where(
              (c) => c.sourceId.equals(sourceId) & c.kind.equalsValue(kind),
            )
            ..orderBy([(c) => OrderingTerm.asc(c.name)]))
          .watch();

  /// [limit] of null returns every channel — the Live TV list and the guide
  /// need the whole lineup (rendering stays lazy via ListView.builder), while
  /// rail previews still cap it. Unnumbered channels sort after numbered ones.
  Stream<List<LiveChannel>> watchLiveChannels(
    int sourceId, {
    String? categoryId,
    int? limit = 300,
  }) {
    final query = select(liveChannels)
      ..where((c) => c.sourceId.equals(sourceId))
      ..orderBy([
        (c) => OrderingTerm.asc(c.channelNumber, nulls: NullsOrder.last),
        (c) => OrderingTerm.asc(c.name),
        (c) => OrderingTerm.asc(c.streamId),
      ]);
    if (limit != null) query.limit(limit);
    if (categoryId != null) {
      query.where((c) => c.categoryId.equals(categoryId));
    }
    return query.watch();
  }

  Stream<List<Movie>> watchMovies(
    int sourceId, {
    String? categoryId,
    CatalogSort sort = CatalogSort.recentlyAdded,
    int limit = 60,
    int offset = 0,
    String search = '',
  }) {
    final query = select(movies)
      ..where((m) => m.sourceId.equals(sourceId))
      ..orderBy(switch (sort) {
        // M3U movies have no addedAt; fall back to name so their order is
        // stable instead of arbitrary.
        CatalogSort.recentlyAdded => [
          (m) => OrderingTerm.desc(m.addedAt, nulls: NullsOrder.last),
          (m) => OrderingTerm.asc(m.name),
          (m) => OrderingTerm.asc(m.streamId),
        ],
        CatalogSort.nameAsc => [(m) => OrderingTerm.asc(m.name)],
        CatalogSort.topRated => [
          (m) => OrderingTerm.desc(m.rating, nulls: NullsOrder.last),
          (m) => OrderingTerm.asc(m.name),
        ],
      })
      ..limit(limit, offset: offset);
    if (categoryId != null) {
      query.where((m) => m.categoryId.equals(categoryId));
    }
    final term = catalogQuery(search);
    if (term.isNotEmpty) {
      query.where((m) => _matchesTitle(m.searchName, term));
    }
    return query.watch();
  }

  Stream<List<SeriesItem>> watchSeries(
    int sourceId, {
    String? categoryId,
    CatalogSort sort = CatalogSort.recentlyAdded,
    int limit = 60,
    int offset = 0,
    String search = '',
  }) {
    final query = select(seriesItems)
      ..where((s) => s.sourceId.equals(sourceId))
      ..orderBy(switch (sort) {
        CatalogSort.recentlyAdded => [
          (s) => OrderingTerm.desc(s.lastModifiedAt, nulls: NullsOrder.last),
          (s) => OrderingTerm.asc(s.name),
          (s) => OrderingTerm.asc(s.seriesId),
        ],
        CatalogSort.nameAsc => [(s) => OrderingTerm.asc(s.name)],
        CatalogSort.topRated => [
          (s) => OrderingTerm.desc(s.rating, nulls: NullsOrder.last),
          (s) => OrderingTerm.asc(s.name),
        ],
      })
      ..limit(limit, offset: offset);
    if (categoryId != null) {
      query.where((s) => s.categoryId.equals(categoryId));
    }
    final term = catalogQuery(search);
    if (term.isNotEmpty) {
      query.where((s) => _matchesTitle(s.searchName, term));
    }
    return query.watch();
  }

  Expression<bool> _matchesTitle(Expression<String> indexedName, String term) =>
      FunctionCallExpression<int>('instr', [
        indexedName,
        Variable.withString(term),
      ]).isBiggerThanValue(0);

  Future<LiveChannel?> getLiveChannel(int sourceId, int streamId) =>
      (select(liveChannels)..where(
            (c) => c.sourceId.equals(sourceId) & c.streamId.equals(streamId),
          ))
          .getSingleOrNull();

  Future<Movie?> getMovie(int sourceId, int streamId) =>
      (select(movies)..where(
            (m) => m.sourceId.equals(sourceId) & m.streamId.equals(streamId),
          ))
          .getSingleOrNull();

  Future<SeriesItem?> getSeriesItem(int sourceId, int seriesId) =>
      (select(seriesItems)..where(
            (s) => s.sourceId.equals(sourceId) & s.seriesId.equals(seriesId),
          ))
          .getSingleOrNull();

  Stream<List<Movie>> watchRecentMovies(int sourceId, {int limit = 20}) =>
      watchMovies(sourceId, limit: limit);

  Stream<List<SeriesItem>> watchRecentSeries(int sourceId, {int limit = 20}) =>
      watchSeries(sourceId, limit: limit);

  // --- EPG ---

  /// Distinct lowercased EPG channel ids for a source — the filter set for
  /// XMLTV import.
  Future<Set<String>> epgChannelIds(int sourceId) async {
    final rows =
        await (selectOnly(liveChannels, distinct: true)
              ..addColumns([liveChannels.epgChannelId])
              ..where(
                liveChannels.sourceId.equals(sourceId) &
                    liveChannels.epgChannelId.isNotNull(),
              ))
            .get();
    return {
      for (final row in rows)
        row.read(liveChannels.epgChannelId)!.trim().toLowerCase(),
    }..remove('');
  }

  Future<void> clearEpg(int sourceId) =>
      (delete(epgProgrammes)..where((p) => p.sourceId.equals(sourceId))).go();

  /// Called once per parsed batch during EPG sync so a multi-hundred-MB
  /// XMLTV file never has to fit in memory.
  Future<void> insertEpgBatch(List<EpgProgrammesCompanion> rows) =>
      batch((b) => b.insertAll(epgProgrammes, rows));

  Future<void> pruneEpg(int sourceId, DateTime endedBefore) =>
      (delete(epgProgrammes)..where(
            (p) =>
                p.sourceId.equals(sourceId) &
                p.endAt.isSmallerThanValue(endedBefore),
          ))
          .go();

  /// Currently-airing programme per channel id (one query for the whole
  /// channel list; the UI refreshes it on a timer).
  Future<Map<String, EpgProgramme>> nowPlaying(
    int sourceId,
    DateTime now,
  ) async {
    final rows =
        await (select(epgProgrammes)..where(
              (p) =>
                  p.sourceId.equals(sourceId) &
                  p.startAt.isSmallerOrEqualValue(now) &
                  p.endAt.isBiggerThanValue(now),
            ))
            .get();
    return {for (final row in rows) row.channelId: row};
  }

  /// Now + upcoming programmes for one channel (preview pane).
  Future<List<EpgProgramme>> upcomingFor(
    int sourceId,
    String channelId,
    DateTime now, {
    int limit = 2,
  }) =>
      (select(epgProgrammes)
            ..where(
              (p) =>
                  p.sourceId.equals(sourceId) &
                  p.channelId.equals(channelId.toLowerCase()) &
                  p.endAt.isBiggerThanValue(now),
            )
            ..orderBy([(p) => OrderingTerm.asc(p.startAt)])
            ..limit(limit))
          .get();

  /// Programmes overlapping [from, to) for one channel — one EPG grid row.
  Future<List<EpgProgramme>> programmesFor(
    int sourceId,
    String channelId,
    DateTime from,
    DateTime to,
  ) =>
      (select(epgProgrammes)
            ..where(
              (p) =>
                  p.sourceId.equals(sourceId) &
                  p.channelId.equals(channelId.toLowerCase()) &
                  p.endAt.isBiggerThanValue(from) &
                  p.startAt.isSmallerThanValue(to),
            )
            ..orderBy([(p) => OrderingTerm.asc(p.startAt)]))
          .get();

  // --- Favorites ---

  Stream<bool> watchIsFavorite(int sourceId, CatalogKind kind, int itemId) =>
      (select(favorites)..where(
            (f) =>
                f.sourceId.equals(sourceId) &
                f.kind.equalsValue(kind) &
                f.itemId.equals(itemId),
          ))
          .watchSingleOrNull()
          .map((row) => row != null);

  /// [notify] false is for applying *pulled* remote data — it keeps the write
  /// from bouncing straight back to the server, without a global flag that
  /// would also swallow concurrent user mutations.
  Future<void> addFavorite({
    required int sourceId,
    required CatalogKind kind,
    required int itemId,
    required String name,
    String? imageUrl,
    bool notify = true,
  }) async {
    await into(favorites).insertOnConflictUpdate(
      FavoritesCompanion.insert(
        sourceId: sourceId,
        kind: kind,
        itemId: itemId,
        name: name,
        imageUrl: Value(imageUrl),
        addedAt: DateTime.now(),
      ),
    );
    await removeTombstone(sourceId, TombstoneScope.favorite, kind.name, itemId);
    if (notify) _notify((s) => s.favoriteAdded(sourceId, kind, itemId));
  }

  /// [notify] false is for applying a *pulled* remote deletion: no push back
  /// upstream, and no tombstone — the server already has one.
  Future<void> removeFavorite(
    int sourceId,
    CatalogKind kind,
    int itemId, {
    bool notify = true,
  }) async {
    await (delete(favorites)..where(
          (f) =>
              f.sourceId.equals(sourceId) &
              f.kind.equalsValue(kind) &
              f.itemId.equals(itemId),
        ))
        .go();
    if (notify) {
      await _putTombstone(sourceId, TombstoneScope.favorite, kind.name, itemId);
      _notify((s) => s.favoriteRemoved(sourceId, kind, itemId));
    }
  }

  Stream<List<Favorite>> watchFavorites(int sourceId, {int? limit = 60}) {
    final query = select(favorites)
      ..where((f) => f.sourceId.equals(sourceId))
      ..orderBy([(f) => OrderingTerm.desc(f.addedAt)]);
    if (limit != null) query.limit(limit);
    return query.watch();
  }

  /// Every favorite for a source — used by the sync reconcile, not the UI.
  Future<List<Favorite>> allFavorites(int sourceId) =>
      (select(favorites)..where((f) => f.sourceId.equals(sourceId))).get();

  // --- Playback positions (Continue Watching) ---

  Future<void> savePosition(
    PlaybackPositionsCompanion position, {
    bool notify = true,
  }) async {
    await into(playbackPositions).insertOnConflictUpdate(position);
    await removeTombstone(
      position.sourceId.value,
      TombstoneScope.progress,
      position.kind.value.name,
      position.itemId.value,
    );
    if (notify) _notify((s) => s.progressSaved(position));
  }

  /// [notify] false is for applying a *pulled* remote deletion: no push back
  /// upstream, and no tombstone — the server already has one.
  Future<void> deletePosition(
    int sourceId,
    WatchKind kind,
    int itemId, {
    bool notify = true,
  }) async {
    final existing =
        await (select(playbackPositions)..where(
              (p) =>
                  p.sourceId.equals(sourceId) &
                  p.kind.equalsValue(kind) &
                  p.itemId.equals(itemId),
            ))
            .getSingleOrNull();
    await (delete(playbackPositions)..where(
          (p) =>
              p.sourceId.equals(sourceId) &
              p.kind.equalsValue(kind) &
              p.itemId.equals(itemId),
        ))
        .go();
    if (notify && existing != null) {
      await _putTombstone(
        sourceId,
        TombstoneScope.progress,
        kind.name,
        itemId,
        seriesId: existing.seriesId,
      );
      _notify((s) => s.progressRemoved(existing));
    }
  }

  /// Clears every in-progress episode of a series. Continue Watching collapses
  /// a series to one card, so removing that card must drop all of its episodes,
  /// not just the one shown. Goes through [deletePosition] so each episode still
  /// gets its own tombstone and notification.
  Future<void> deletePositionsForSeries(int sourceId, int seriesId) async {
    final rows =
        await (select(playbackPositions)..where(
              (p) =>
                  p.sourceId.equals(sourceId) &
                  p.kind.equalsValue(WatchKind.episode) &
                  p.seriesId.equals(seriesId),
            ))
            .get();
    for (final row in rows) {
      await deletePosition(sourceId, WatchKind.episode, row.itemId);
    }
  }

  // --- Sync tombstones ---

  Future<void> _putTombstone(
    int sourceId,
    TombstoneScope scope,
    String kind,
    int itemId, {
    int? seriesId,
  }) => into(syncTombstones).insertOnConflictUpdate(
    SyncTombstonesCompanion.insert(
      sourceId: sourceId,
      scope: scope,
      kind: kind,
      itemId: itemId,
      seriesId: Value(seriesId),
      deletedAt: DateTime.now(),
    ),
  );

  Future<void> removeTombstone(
    int sourceId,
    TombstoneScope scope,
    String kind,
    int itemId,
  ) =>
      (delete(syncTombstones)..where(
            (t) =>
                t.sourceId.equals(sourceId) &
                t.scope.equalsValue(scope) &
                t.kind.equals(kind) &
                t.itemId.equals(itemId),
          ))
          .go();

  /// Pending deletions for a source — consumed by the sync reconcile.
  Future<List<SyncTombstone>> tombstones(int sourceId, TombstoneScope scope) =>
      (select(syncTombstones)..where(
            (t) => t.sourceId.equals(sourceId) & t.scope.equalsValue(scope),
          ))
          .get();

  Future<void> recordWatched(int source, CatalogKind kind, int item) =>
      into(watchedTitles).insertOnConflictUpdate(
        WatchedTitlesCompanion.insert(
          sourceId: source,
          kind: kind,
          itemId: item,
          watchedAt: DateTime.now(),
        ),
      );

  Future<void> recordWatchedEpisode(int sourceId, int episodeId) =>
      into(watchedEpisodes).insert(
        WatchedEpisodesCompanion.insert(
          sourceId: sourceId,
          episodeId: episodeId,
        ),
        mode: InsertMode.insertOrIgnore,
      );

  /// Every resume point for a source — used by the sync reconcile, not the UI.
  Future<List<PlaybackPosition>> allPositions(int sourceId) => (select(
    playbackPositions,
  )..where((p) => p.sourceId.equals(sourceId))).get();

  Stream<PlaybackPosition?> watchPosition(
    int sourceId,
    WatchKind kind,
    int itemId,
  ) =>
      (select(playbackPositions)..where(
            (p) =>
                p.sourceId.equals(sourceId) &
                p.kind.equalsValue(kind) &
                p.itemId.equals(itemId),
          ))
          .watchSingleOrNull();

  /// In-progress episodes of a series, newest first — the first row drives
  /// "Resume S2 E5", the rest drive per-episode progress bars.
  Stream<List<PlaybackPosition>> watchSeriesPositions(
    int sourceId,
    int seriesId,
  ) =>
      (select(playbackPositions)
            ..where(
              (p) =>
                  p.sourceId.equals(sourceId) &
                  p.kind.equalsValue(WatchKind.episode) &
                  p.seriesId.equals(seriesId),
            )
            ..orderBy([
              (p) => OrderingTerm.desc(p.updatedAt),
              (p) => OrderingTerm.desc(p.rowId),
            ]))
          .watch();

  Future<List<PlaybackPosition>> caughtUpEpisodes(int sourceId) =>
      (select(playbackPositions)
            ..where(
              (p) =>
                  p.sourceId.equals(sourceId) &
                  p.kind.equalsValue(WatchKind.episode) &
                  p.seriesId.isNotNull() &
                  p.durationSecs.isBiggerThanValue(0) &
                  p.positionSecs.isBiggerOrEqual(p.durationSecs),
            )
            ..orderBy([
              (p) => OrderingTerm.desc(p.updatedAt),
              (p) => OrderingTerm.desc(p.rowId),
            ]))
          .get();

  Future<PlaybackPosition?> latestSeriesPosition(int sourceId, int seriesId) =>
      (select(playbackPositions)
            ..where(
              (p) =>
                  p.sourceId.equals(sourceId) &
                  p.seriesId.equals(seriesId) &
                  p.kind.equalsValue(WatchKind.episode),
            )
            ..orderBy([
              (p) => OrderingTerm.desc(p.updatedAt),
              (p) => OrderingTerm.desc(p.rowId),
            ])
            ..limit(1))
          .getSingleOrNull();

  /// One row per movie and per series (its most recently watched episode).
  Stream<List<PlaybackPosition>> watchContinueWatching(
    int sourceId, {
    int limit = 20,
  }) =>
      (select(playbackPositions)
            ..where((p) => p.sourceId.equals(sourceId))
            ..orderBy([
              (p) => OrderingTerm.desc(p.updatedAt),
              (p) => OrderingTerm.desc(p.rowId),
            ]))
          .watch()
          .map((rows) {
            final seenSeries = <int>{};
            final result = <PlaybackPosition>[];
            for (final p in rows) {
              if (p.seriesId case final seriesId?
                  when !seenSeries.add(seriesId)) {
                continue;
              }
              if (p.isCompletedEpisode) continue;
              result.add(p);
              if (result.length >= limit) break;
            }
            return result;
          });

  // --- Search ---

  // Bound parameters and instr() make %, _ and backslashes literal.
  // Pipe delimits equivalent spellings of one title in its stored search key.
  String _searchOrder(String term) =>
      """
    CASE WHEN instr(c.search_name, '|' || $term || '|') > 0 THEN 0
         WHEN instr(replace(c.search_name,'|',' '), ' ' || $term || ' ') > 0 THEN 1
         WHEN instr(replace(c.search_name,'|',' '), ' ' || $term) > 0 THEN 2
         ELSE 3 END
  """;

  Selectable<LiveChannel> _channelSelection(
    int sourceId, {
    required String text,
    String? categoryId,
    required LiveCollection collection,
    int? limit,
  }) {
    final term = catalogQuery(text);
    final number = int.tryParse(term);
    final join = switch (collection) {
      LiveCollection.all => '',
      LiveCollection.recent =>
        'JOIN recent_channels r ON r.source_id=c.source_id AND r.stream_id=c.stream_id',
      LiveCollection.favorites =>
        "JOIN favorites f ON f.source_id=c.source_id AND f.item_id=c.stream_id AND f.kind='live'",
    };
    final variables = <Variable>[Variable.withInt(sourceId)];
    String bind(Variable value) {
      variables.add(value);
      return '?${variables.length}';
    }

    final conditions = ['c.source_id=?1'];
    if (categoryId != null) {
      conditions.add('c.category_id=${bind(Variable.withString(categoryId))}');
    }
    final order = <String>[];
    if (text.trim().isNotEmpty) {
      if (term.isEmpty) conditions.add('0');
      final q = bind(Variable.withString(term));
      final matches = ['instr(c.search_name,$q)>0'];
      if (number != null) {
        final n = bind(Variable.withInt(number));
        matches.add('c.channel_number=$n');
        order.add('CASE WHEN c.channel_number=$n THEN 0 ELSE 1 END');
      }
      conditions.add("(${matches.join(' OR ')})");
      order.add(_searchOrder(q));
    }
    if (collection == LiveCollection.recent) order.add('r.id DESC');
    if (collection == LiveCollection.favorites) order.add('f.added_at DESC');
    order.addAll(['c.channel_number NULLS LAST', 'c.name', 'c.stream_id']);
    final cap = limit == null ? '' : 'LIMIT ${bind(Variable.withInt(limit))}';
    return customSelect(
      'SELECT c.* FROM live_channels c $join WHERE ${conditions.join(' AND ')} ORDER BY ${order.join(', ')} $cap',
      variables: variables,
      readsFrom: {
        liveChannels,
        if (collection == LiveCollection.recent) recentChannels,
        if (collection == LiveCollection.favorites) favorites,
      },
    ).map((row) => liveChannels.map(row.data));
  }

  Stream<List<LiveChannel>> watchChannelCollection(
    int sourceId,
    LiveCollection collection, {
    String? categoryId,
    String query = '',
    int? limit,
  }) => _channelSelection(
    sourceId,
    text: query,
    categoryId: categoryId,
    collection: collection,
    limit: limit,
  ).watch();

  /// Only record a channel that still belongs to this source. The history
  /// survives catalog refreshes and stays bounded, including retired channels.
  Future<void> recordLivePlayback(
    int sourceId,
    int streamId,
  ) => transaction(() async {
    await customUpdate(
      'INSERT OR REPLACE INTO recent_channels (source_id, stream_id) SELECT source_id, stream_id FROM live_channels WHERE source_id=? AND stream_id=?',
      variables: [Variable.withInt(sourceId), Variable.withInt(streamId)],
      updates: {recentChannels},
    );
    await customUpdate(
      'DELETE FROM recent_channels WHERE source_id=?1 AND id NOT IN (SELECT id FROM recent_channels WHERE source_id=?1 ORDER BY id DESC LIMIT 30)',
      variables: [Variable.withInt(sourceId)],
      updates: {recentChannels},
    );
  });

  Future<List<LiveChannel>> searchLiveChannels(
    int sourceId,
    String query, {
    int limit = 30,
  }) => _channelSelection(
    sourceId,
    text: query,
    collection: LiveCollection.all,
    limit: limit,
  ).get();

  /// Day buckets use UTC dates so DST changes never split playback counters.
  static int liveDay(DateTime at) =>
      at.toUtc().millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

  Stream<List<LiveViewingData>> watchLiveViewing(int sourceId, String viewer) =>
      (select(liveViewing)..where(
            (r) => r.sourceId.equals(sourceId) & r.viewer.equals(viewer),
          ))
          .watch();

  Future<void> addLiveViewing(
    int sourceId,
    String viewer,
    int streamId,
    DateTime at,
    int seconds,
  ) => transaction(() async {
    if (seconds <= 0) return;
    final day = liveDay(at);
    await customUpdate(
      '''INSERT INTO live_viewing (source_id, viewer, day, stream_id, seconds, last_watched)
         SELECT source_id, ?, ?, stream_id, ?, ? FROM live_channels
         WHERE source_id=? AND stream_id=?
         ON CONFLICT (source_id, viewer, day, stream_id) DO UPDATE SET
         seconds=live_viewing.seconds+excluded.seconds,
         last_watched=MAX(live_viewing.last_watched, excluded.last_watched)''',
      variables: [
        Variable.withString(viewer),
        Variable.withInt(day),
        Variable.withInt(seconds),
        Variable.withDateTime(at),
        Variable.withInt(sourceId),
        Variable.withInt(streamId),
      ],
      updates: {liveViewing},
    );
    await (delete(liveViewing)..where(
          (r) =>
              r.sourceId.equals(sourceId) &
              r.viewer.equals(viewer) &
              r.day.isSmallerThanValue(day - 29),
        ))
        .go();
  });

  Stream<List<LiveTuningData>> watchLiveTuning(int sourceId, String viewer) =>
      (select(liveTuning)..where(
            (r) => r.sourceId.equals(sourceId) & r.viewer.equals(viewer),
          ))
          .watch();

  Future<void> saveLiveTuning(
    int sourceId,
    String viewer,
    String channelKey, {
    Value<int?> preferred = const Value.absent(),
    Value<int?> successful = const Value.absent(),
  }) async {
    final row = LiveTuningCompanion.insert(
      sourceId: sourceId,
      viewer: viewer,
      channelKey: channelKey,
      preferredStream: preferred,
      successfulStream: successful,
    );
    await into(liveTuning).insert(row, onConflict: DoUpdate((_) => row));
  }

  Stream<List<LiveGuideLink>> watchLiveGuideLinks(int sourceId) => (select(
    liveGuideLinks,
  )..where((r) => r.sourceId.equals(sourceId))).watch();

  Future<List<LiveGuideLink>> liveGuideLinksFor(int sourceId) =>
      (select(liveGuideLinks)..where((r) => r.sourceId.equals(sourceId))).get();

  Future<Map<String, List<String>>> liveGuideNamesFor(int sourceId) async {
    final row =
        await (select(recommendationSnapshots)..where(
              (r) =>
                  r.sourceId.equals(sourceId) &
                  r.slot.equals('live.guide-names.v1'),
            ))
            .getSingleOrNull();
    if (row == null) return const {};
    final raw = jsonDecode(row.payload) as Map<String, dynamic>;
    return {
      for (final entry in raw.entries)
        entry.key: List<String>.from(entry.value as List),
    };
  }

  Future<void> saveLiveGuideLink(int sourceId, String key, String id) =>
      into(liveGuideLinks)
          .insertOnConflictUpdate(
            LiveGuideLinksCompanion.insert(
              sourceId: sourceId,
              channelKey: key,
              guideId: id,
              manual: true,
            ),
          )
          .then((_) {});

  Future<void> resetLiveGuideLink(int sourceId, String key) =>
      (delete(liveGuideLinks)..where(
            (r) => r.sourceId.equals(sourceId) & r.channelKey.equals(key),
          ))
          .go()
          .then((_) {});

  Future<void> replaceAutomaticGuideLinks(
    int sourceId,
    Map<String, String> links,
  ) => transaction(() async {
    await (delete(
      liveGuideLinks,
    )..where((r) => r.sourceId.equals(sourceId) & r.manual.equals(false))).go();
    await batch(
      (b) => b.insertAll(liveGuideLinks, [
        for (final link in links.entries)
          LiveGuideLinksCompanion.insert(
            sourceId: sourceId,
            channelKey: link.key,
            guideId: link.value,
            manual: false,
          ),
      ], mode: InsertMode.insertOrIgnore),
    );
  });

  Future<List<T>> _searchTitles<T extends Object>(
    TableInfo<Table, T> table,
    int sourceId,
    String query,
    int limit,
    String tieBreak,
  ) {
    final term = catalogQuery(query);
    if (term.isEmpty) return Future.value([]);
    return customSelect(
      'SELECT c.* FROM ${table.actualTableName} c WHERE c.source_id=?1 AND instr(c.search_name,?2)>0 ORDER BY ${_searchOrder('?2')}, $tieBreak LIMIT ?3',
      variables: [
        Variable.withInt(sourceId),
        Variable.withString(term),
        Variable.withInt(limit),
      ],
      readsFrom: {table},
    ).asyncMap((row) => table.map(row.data)).get();
  }

  Future<List<Movie>> searchMovies(
    int sourceId,
    String query, {
    int limit = 30,
  }) => _searchTitles(
    movies,
    sourceId,
    query,
    limit,
    'c.added_at DESC NULLS LAST, c.name, c.stream_id',
  );
  Future<List<SeriesItem>> searchSeries(
    int sourceId,
    String query, {
    int limit = 30,
  }) => _searchTitles(
    seriesItems,
    sourceId,
    query,
    limit,
    'c.last_modified_at DESC NULLS LAST, c.name, c.series_id',
  );

  Future<({int live, int movies, int series})> catalogCounts(
    int sourceId,
  ) async {
    Future<int> count(
      TableInfo<Table, dynamic> table,
      Column<int> sourceColumn,
    ) async {
      final c = countAll();
      final row =
          await (selectOnly(table)
                ..addColumns([c])
                ..where(sourceColumn.equals(sourceId)))
              .getSingle();
      return row.read(c) ?? 0;
    }

    return (
      live: await count(liveChannels, liveChannels.sourceId),
      movies: await count(movies, movies.sourceId),
      series: await count(seriesItems, seriesItems.sourceId),
    );
  }

  // --- Downloads ---

  Stream<List<DownloadItem>> watchDownloads(int sourceId) =>
      (select(downloads)
            ..where((d) => d.sourceId.equals(sourceId))
            ..orderBy([(d) => OrderingTerm.desc(d.createdAt)]))
          .watch();

  Stream<List<DownloadItem>> watchWatchedDownloads(int sourceId) {
    final query =
        select(downloads).join([
          leftOuterJoin(
            watchedEpisodes,
            watchedEpisodes.sourceId.equalsExp(downloads.sourceId) &
                watchedEpisodes.episodeId.equalsExp(downloads.itemId),
            useColumns: false,
          ),
          leftOuterJoin(
            playbackPositions,
            playbackPositions.sourceId.equalsExp(downloads.sourceId) &
                playbackPositions.kind.equalsValue(WatchKind.episode) &
                playbackPositions.itemId.equalsExp(downloads.itemId),
            useColumns: false,
          ),
        ])..where(
          downloads.sourceId.equals(sourceId) &
              downloads.kind.equalsValue(WatchKind.episode) &
              downloads.status.equalsValue(DownloadStatus.done) &
              (watchedEpisodes.episodeId.isNotNull() |
                  (playbackPositions.durationSecs.isBiggerThanValue(0) &
                      playbackPositions.positionSecs.isBiggerOrEqual(
                        playbackPositions.durationSecs,
                      ))),
        );
    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(downloads)).toList(),
    );
  }

  Stream<DownloadItem?> watchDownload(
    int sourceId,
    WatchKind kind,
    int itemId,
  ) =>
      (select(downloads)..where(
            (d) =>
                d.sourceId.equals(sourceId) &
                d.kind.equalsValue(kind) &
                d.itemId.equals(itemId),
          ))
          .watchSingleOrNull();

  Future<DownloadItem?> getDownload(int sourceId, WatchKind kind, int itemId) =>
      (select(downloads)..where(
            (d) =>
                d.sourceId.equals(sourceId) &
                d.kind.equalsValue(kind) &
                d.itemId.equals(itemId),
          ))
          .getSingleOrNull();

  Future<void> upsertDownload(DownloadsCompanion download) =>
      into(downloads).insertOnConflictUpdate(download);

  Future<void> markDownloadDone(
    int sourceId,
    WatchKind kind,
    int itemId, {
    int? totalBytes,
    String? filePath,
  }) =>
      (update(downloads)..where(
            (d) =>
                d.sourceId.equals(sourceId) &
                d.kind.equalsValue(kind) &
                d.itemId.equals(itemId),
          ))
          .write(
            DownloadsCompanion(
              status: const Value(DownloadStatus.done),
              totalBytes: Value(totalBytes),
              filePath: filePath == null
                  ? const Value.absent()
                  : Value(filePath),
            ),
          );

  Future<void> markDownloadFailed(
    int sourceId,
    WatchKind kind,
    int itemId, {
    bool noSpace = false,
  }) =>
      (update(downloads)..where(
            (d) =>
                d.sourceId.equals(sourceId) &
                d.kind.equalsValue(kind) &
                d.itemId.equals(itemId),
          ))
          .write(
            DownloadsCompanion(
              status: Value(
                noSpace ? DownloadStatus.noSpace : DownloadStatus.failed,
              ),
            ),
          );

  Future<void> deleteDownload(int sourceId, WatchKind kind, int itemId) =>
      (delete(downloads)..where(
            (d) =>
                d.sourceId.equals(sourceId) &
                d.kind.equalsValue(kind) &
                d.itemId.equals(itemId),
          ))
          .go();
}

/// Scratch file for a single refresh. Only create the tables we populate.
/// The active database owns the browse indexes.
class CatalogStagingDatabase extends AppDatabase {
  CatalogStagingDatabase(File file)
    : super._staging(
        NativeDatabase.createInBackground(
          file,
          isolateSetup: isWebOsPlatform ? configureWebOsSqlite : null,
        ),
      );

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      for (final table in <TableInfo<Table, Object?>>[
        sources,
        categories,
        liveChannels,
        movies,
        seriesItems,
        epgProgrammes,
      ]) {
        await m.createTable(table);
      }
    },
  );
}
