import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/app_paths.dart';

part 'app_database.g.dart';

/// Wraps a user search term as a LIKE pattern, escaping the wildcards `%` and
/// `_` (and the escape char itself) so they match literally instead of acting
/// as wildcards. Pair with `like(..., escapeChar: r'\')`.
String _likePattern(String query) {
  final escaped = query.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}');
  return '%$escaped%';
}

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
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}

enum CatalogKind { live, vod, series }

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

class LiveChannels extends Table {
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
class Movies extends Table {
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

class SeriesItems extends Table {
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

/// What a playback position points at. Live TV is never tracked.
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

enum DownloadStatus { downloading, done }

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

/// Observer notified after local favorite/progress mutations so a backend
/// sync layer can mirror them upstream. Kept in the db layer (no backend
/// import) so the dependency arrow points backend → db, never the reverse.
abstract interface class SyncSink {
  void favoriteAdded(int sourceId, CatalogKind kind, int itemId);
  void favoriteRemoved(int sourceId, CatalogKind kind, int itemId);
  void progressSaved(PlaybackPositionsCompanion position);
  void progressRemoved(PlaybackPosition position);
}

@DriftDatabase(
  tables: [
    Sources,
    Categories,
    LiveChannels,
    Movies,
    SeriesItems,
    EpgProgrammes,
    Favorites,
    PlaybackPositions,
    SyncTombstones,
    Downloads,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase()
    : super(
        driftDatabase(
          name: 'zauxoflix',
          native: DriftNativeOptions(databaseDirectory: appDataDirectory),
        ),
      );

  AppDatabase.forTesting(super.executor);

  /// Attached by the sync layer at runtime; null in tests / when logged out.
  SyncSink? syncSink;

  void _notify(void Function(SyncSink sink) emit) {
    final sink = syncSink;
    if (sink != null) emit(sink);
  }

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
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
      if (from < 6) {
        await m.addColumn(downloads, downloads.episodeImageUrl);
      }
    },
  );

  // --- Sources ---

  Stream<Source?> watchActiveSource() =>
      (select(sources)..limit(1)).watchSingleOrNull();

  Future<int> insertSource(SourcesCompanion source) =>
      into(sources).insert(source);

  Future<void> deleteSource(int sourceId) => transaction(() async {
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
    await delete(favorites).go();
    await delete(playbackPositions).go();
    await delete(syncTombstones).go();
  });

  /// Full local wipe on sign-out: sources, catalog, EPG, favorites and resume
  /// points all go. Server-side copies are untouched and come back on the
  /// next sign-in. Bypasses [_notify] — the purge must not sync upstream.
  Future<void> wipeAll() => transaction(() async {
    for (final table in allTables) {
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
    await batch((b) => b.insertAll(liveChannels, rows));
  });

  Future<void> replaceMovies(int sourceId, List<MoviesCompanion> rows) =>
      transaction(() async {
        await (delete(movies)..where((m) => m.sourceId.equals(sourceId))).go();
        await batch((b) => b.insertAll(movies, rows));
      });

  Future<void> replaceSeries(int sourceId, List<SeriesItemsCompanion> rows) =>
      transaction(() async {
        await (delete(
          seriesItems,
        )..where((s) => s.sourceId.equals(sourceId))).go();
        await batch((b) => b.insertAll(seriesItems, rows));
      });

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
  }) {
    final query = select(movies)
      ..where((m) => m.sourceId.equals(sourceId))
      ..orderBy(switch (sort) {
        // M3U movies have no addedAt; fall back to name so their order is
        // stable instead of arbitrary.
        CatalogSort.recentlyAdded => [
          (m) => OrderingTerm.desc(m.addedAt, nulls: NullsOrder.last),
          (m) => OrderingTerm.asc(m.name),
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
    return query.watch();
  }

  Stream<List<SeriesItem>> watchSeries(
    int sourceId, {
    String? categoryId,
    CatalogSort sort = CatalogSort.recentlyAdded,
    int limit = 60,
    int offset = 0,
  }) {
    final query = select(seriesItems)
      ..where((s) => s.sourceId.equals(sourceId))
      ..orderBy(switch (sort) {
        CatalogSort.recentlyAdded => [
          (s) => OrderingTerm.desc(s.lastModifiedAt, nulls: NullsOrder.last),
          (s) => OrderingTerm.asc(s.name),
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
    return query.watch();
  }

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

  Stream<List<Favorite>> watchFavorites(int sourceId, {int limit = 60}) =>
      (select(favorites)
            ..where((f) => f.sourceId.equals(sourceId))
            ..orderBy([(f) => OrderingTerm.desc(f.addedAt)])
            ..limit(limit))
          .watch();

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
            ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)]))
          .watch();

  /// One row per movie and per series (its most recently watched episode).
  Stream<List<PlaybackPosition>> watchContinueWatching(
    int sourceId, {
    int limit = 20,
  }) =>
      (select(playbackPositions)
            ..where((p) => p.sourceId.equals(sourceId))
            ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)]))
          .watch()
          .map((rows) {
            final seenSeries = <int>{};
            final result = <PlaybackPosition>[];
            for (final p in rows) {
              if (p.seriesId case final seriesId?
                  when !seenSeries.add(seriesId)) {
                continue;
              }
              result.add(p);
              if (result.length >= limit) break;
            }
            return result;
          });

  // --- Search ---

  Future<List<LiveChannel>> searchLiveChannels(
    int sourceId,
    String query, {
    int limit = 30,
  }) =>
      (select(liveChannels)
            ..where(
              (c) =>
                  c.sourceId.equals(sourceId) &
                  c.name.like(_likePattern(query), escapeChar: r'\'),
            )
            ..orderBy([(c) => OrderingTerm.asc(c.name)])
            ..limit(limit))
          .get();

  Future<List<Movie>> searchMovies(
    int sourceId,
    String query, {
    int limit = 30,
  }) =>
      (select(movies)
            ..where(
              (m) =>
                  m.sourceId.equals(sourceId) &
                  m.name.like(_likePattern(query), escapeChar: r'\'),
            )
            ..orderBy([
              (m) => OrderingTerm.desc(m.addedAt, nulls: NullsOrder.last),
              (m) => OrderingTerm.asc(m.name),
            ])
            ..limit(limit))
          .get();

  Future<List<SeriesItem>> searchSeries(
    int sourceId,
    String query, {
    int limit = 30,
  }) =>
      (select(seriesItems)
            ..where(
              (s) =>
                  s.sourceId.equals(sourceId) &
                  s.name.like(_likePattern(query), escapeChar: r'\'),
            )
            ..orderBy([
              (s) =>
                  OrderingTerm.desc(s.lastModifiedAt, nulls: NullsOrder.last),
              (s) => OrderingTerm.asc(s.name),
            ])
            ..limit(limit))
          .get();

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
