import '../db/app_database.dart';

/// The backend's `ItemType` enum on the wire.
enum BackendItemType {
  live,
  movie,
  series;

  String get wire => switch (this) {
    BackendItemType.live => 'LIVE',
    BackendItemType.movie => 'MOVIE',
    BackendItemType.series => 'SERIES',
  };

  static BackendItemType? parse(String? raw) => switch (raw) {
    'LIVE' => BackendItemType.live,
    'MOVIE' => BackendItemType.movie,
    'SERIES' => BackendItemType.series,
    _ => null,
  };
}

// --- Favorites: local CatalogKind <-> backend ItemType ---

BackendItemType favoriteItemType(CatalogKind kind) => switch (kind) {
  CatalogKind.live => BackendItemType.live,
  CatalogKind.vod => BackendItemType.movie,
  CatalogKind.series => BackendItemType.series,
};

CatalogKind favoriteKindFrom(BackendItemType type) => switch (type) {
  BackendItemType.live => CatalogKind.live,
  BackendItemType.movie => CatalogKind.vod,
  BackendItemType.series => CatalogKind.series,
};

// --- Watch progress: local (WatchKind, itemId, seriesId) <-> backend key ---

/// The backend progress identity: a movie is (MOVIE, streamId, "") while an
/// episode is (SERIES, seriesId, episodeId).
class BackendProgressKey {
  const BackendProgressKey(this.itemType, this.itemId, this.episodeId);

  final BackendItemType itemType;
  final String itemId;
  final String episodeId;

  /// Stable string for map lookups.
  String get token => '${itemType.wire}:$itemId:$episodeId';
}

/// Maps a local resume point to its backend key, or null when it can't be
/// represented (an episode with no series id).
BackendProgressKey? progressKey(WatchKind kind, int itemId, int? seriesId) {
  switch (kind) {
    case WatchKind.movie:
      return BackendProgressKey(BackendItemType.movie, '$itemId', '');
    case WatchKind.episode:
      if (seriesId == null) return null;
      return BackendProgressKey(BackendItemType.series, '$seriesId', '$itemId');
  }
}

/// A local resume point identity resolved from a backend progress row.
class LocalProgressRef {
  const LocalProgressRef(this.kind, this.itemId, this.seriesId);

  final WatchKind kind;
  final int itemId;
  final int? seriesId;
}

/// Maps a backend progress row back to a local identity, or null when it isn't
/// something the client tracks (live progress, or a series-level row with no
/// episode id).
LocalProgressRef? localProgressRef(
  BackendItemType type,
  String itemId,
  String episodeId,
) {
  switch (type) {
    case BackendItemType.movie:
      final id = int.tryParse(itemId);
      return id == null ? null : LocalProgressRef(WatchKind.movie, id, null);
    case BackendItemType.series:
      if (episodeId.isEmpty) return null;
      final seriesId = int.tryParse(itemId);
      final episode = int.tryParse(episodeId);
      return (seriesId == null || episode == null)
          ? null
          : LocalProgressRef(WatchKind.episode, episode, seriesId);
    case BackendItemType.live:
      return null;
  }
}
