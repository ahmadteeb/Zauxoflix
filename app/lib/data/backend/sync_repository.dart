import 'dart:async';

import 'package:drift/drift.dart';

import '../db/app_database.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_mapping.dart';

/// Mirrors the local favorites / watch-progress stores against the backend's
/// per-user sync endpoints. Implements [SyncSink] so every local mutation is
/// pushed upstream, and offers [reconcile] to merge the server's state down on
/// login. Resolution of last-write-wins is server-authoritative for progress
/// (compared via `updatedAt`); favorites use a union merge.
class SyncRepository implements SyncSink {
  SyncRepository(this._client, this._db);

  final SupabaseClient _client;
  final AppDatabase _db;

  // --- SyncSink: fire-and-forget pushes on local mutations ---

  @override
  void favoriteAdded(int sourceId, CatalogKind kind, int itemId) =>
      unawaited(pushFavorite(kind, itemId));

  @override
  void favoriteRemoved(int sourceId, CatalogKind kind, int itemId) =>
      unawaited(pushUnfavorite(kind, itemId));

  @override
  void progressSaved(PlaybackPositionsCompanion position) => unawaited(
    pushProgress(
      position.kind.value,
      position.itemId.value,
      position.seriesId.present ? position.seriesId.value : null,
      position.positionSecs.value,
      position.durationSecs.value,
      subtitle: position.subtitle.present ? position.subtitle.value : null,
    ),
  );

  @override
  void progressRemoved(PlaybackPosition position) => unawaited(
    pushDeleteProgress(position.kind, position.itemId, position.seriesId),
  );

  // --- Awaitable pushes (also used by reconcile) ---

  Future<void> pushFavorite(CatalogKind kind, int itemId) => _swallow(
    () => _client.rpc<void>(
      'sync_favorite',
      params: {
        'item_type': favoriteItemType(kind).wire,
        'item_id': '$itemId',
        'removed': false,
      },
    ),
  );

  Future<void> pushUnfavorite(CatalogKind kind, int itemId) => _swallow(
    () => _client.rpc<void>(
      'sync_favorite',
      params: {
        'item_type': favoriteItemType(kind).wire,
        'item_id': '$itemId',
        'removed': true,
      },
    ),
  );

  Future<void> pushProgress(
    WatchKind kind,
    int itemId,
    int? seriesId,
    int positionSec,
    int durationSec, {
    String? subtitle,
  }) {
    final key = progressKey(kind, itemId, seriesId);
    if (key == null) return Future.value();
    return _swallow(
      () => _client.rpc<void>(
        'sync_progress',
        params: {
          'item_type': key.itemType.wire,
          'item_id': key.itemId,
          'episode_id': key.episodeId,
          'position_sec': positionSec,
          'duration_sec': durationSec,
          'label': subtitle ?? '',
          'removed': false,
        },
      ),
    );
  }

  Future<void> pushDeleteProgress(WatchKind kind, int itemId, int? seriesId) {
    final key = progressKey(kind, itemId, seriesId);
    if (key == null) return Future.value();
    return _swallow(
      () => _client.rpc<void>(
        'sync_progress',
        params: {
          'item_type': key.itemType.wire,
          'item_id': key.itemId,
          'episode_id': key.episodeId,
          'removed': true,
        },
      ),
    );
  }

  // --- Reconcile: merge server state into the local stores on login ---

  Future<void> reconcile(int sourceId) async {
    await _reconcileFavorites(sourceId);
    await _reconcileProgress(sourceId);
  }

  Future<void> _reconcileFavorites(int sourceId) async {
    final remote = await _fetchFavorites();
    final localByToken = {
      for (final f in await _db.allFavorites(sourceId))
        '${favoriteItemType(f.kind).wire}:${f.itemId}': f,
    };
    final tombByToken = <String, SyncTombstone>{};
    for (final t in await _db.tombstones(sourceId, TombstoneScope.favorite)) {
      final kind = CatalogKind.values.asNameMap()[t.kind];
      if (kind == null) continue;
      tombByToken['${favoriteItemType(kind).wire}:${t.itemId}'] = t;
    }
    final remoteTokens = <String>{};

    for (final r in remote) {
      final token = '${r.type.wire}:${r.itemId}';
      remoteTokens.add(token);
      final id = int.tryParse(r.itemId);
      if (id == null) continue;
      final kind = favoriteKindFrom(r.type);
      final local = localByToken[token];
      final tomb = tombByToken[token];

      if (r.deletedAt == null) {
        // Active on the server. A newer local tombstone means the user removed
        // it here while the push was lost — replay the delete.
        if (tomb != null && tomb.deletedAt.isAfter(r.createdAt)) {
          await pushUnfavorite(kind, id);
          continue; // tombstone stays until the server's tombstone comes back
        }
        if (tomb != null) {
          // Re-favorited elsewhere after our removal — the server wins.
          await _db.removeTombstone(
            sourceId,
            TombstoneScope.favorite,
            kind.name,
            id,
          );
        }
        if (local == null) {
          final meta = await _favoriteMeta(sourceId, kind, id);
          if (meta == null) continue; // catalog not synced yet — retried later
          await _db.addFavorite(
            sourceId: sourceId,
            kind: kind,
            itemId: id,
            name: meta.name,
            imageUrl: meta.imageUrl,
            notify: false, // pulled from the server — don't echo it back
          );
        }
      } else {
        // Tombstoned on the server. A favorite added here afterwards revives
        // it; otherwise apply the removal locally.
        if (local != null && local.addedAt.isAfter(r.deletedAt!)) {
          await pushFavorite(kind, id);
        } else if (local != null) {
          await _db.removeFavorite(sourceId, kind, id, notify: false);
        }
        if (tomb != null) {
          await _db.removeTombstone(
            sourceId,
            TombstoneScope.favorite,
            kind.name,
            id,
          );
        }
      }
    }

    // Seed the server with anything that only existed on this device, and
    // drop tombstones for items the server never had.
    for (final entry in localByToken.entries) {
      if (!remoteTokens.contains(entry.key)) {
        await pushFavorite(entry.value.kind, entry.value.itemId);
      }
    }
    for (final entry in tombByToken.entries) {
      if (!remoteTokens.contains(entry.key)) {
        final t = entry.value;
        await _db.removeTombstone(
          sourceId,
          TombstoneScope.favorite,
          t.kind,
          t.itemId,
        );
      }
    }
  }

  Future<void> _reconcileProgress(int sourceId) async {
    final remote = await _fetchProgress();
    final local = await _db.allPositions(sourceId);
    final localByToken = <String, PlaybackPosition>{};
    for (final p in local) {
      final key = progressKey(p.kind, p.itemId, p.seriesId);
      if (key != null) localByToken[key.token] = p;
    }
    final tombByToken = <String, SyncTombstone>{};
    for (final t in await _db.tombstones(sourceId, TombstoneScope.progress)) {
      final kind = WatchKind.values.asNameMap()[t.kind];
      if (kind == null) continue;
      final key = progressKey(kind, t.itemId, t.seriesId);
      if (key != null) tombByToken[key.token] = t;
    }
    final remoteByToken = {for (final r in remote) r.token: r};

    for (final r in remote) {
      final ref = localProgressRef(r.type, r.itemId, r.episodeId);
      if (ref == null) continue;
      final existing = localByToken[r.token];
      final tomb = tombByToken[r.token];

      if (r.deletedAt case final remoteDeleted?) {
        // A deletion is just the newest write: a local resume point saved
        // after it revives the row, anything older is removed.
        if (existing != null && existing.updatedAt.isAfter(remoteDeleted)) {
          await pushProgress(
            existing.kind,
            existing.itemId,
            existing.seriesId,
            existing.positionSecs,
            existing.durationSecs,
            subtitle: existing.subtitle,
          );
        } else if (existing != null) {
          await _db.deletePosition(
            sourceId,
            ref.kind,
            ref.itemId,
            notify: false,
          );
        }
        if (tomb != null) {
          await _db.removeTombstone(
            sourceId,
            TombstoneScope.progress,
            ref.kind.name,
            ref.itemId,
          );
        }
        // Fully handled — keep the LWW push loop below from re-pushing it.
        localByToken.remove(r.token);
        continue;
      }

      // Active on the server. A newer local tombstone means the user cleared
      // it here while the push was lost — replay the delete.
      if (tomb != null && tomb.deletedAt.isAfter(r.updatedAt)) {
        await pushDeleteProgress(ref.kind, ref.itemId, ref.seriesId);
        continue; // tombstone stays until the server's tombstone comes back
      }
      if (tomb != null) {
        await _db.removeTombstone(
          sourceId,
          TombstoneScope.progress,
          ref.kind.name,
          ref.itemId,
        );
      }
      // Server-authoritative last-write-wins: only pull when strictly newer.
      if (existing != null && !r.updatedAt.isAfter(existing.updatedAt)) {
        continue;
      }
      final meta = await _progressMeta(sourceId, ref);
      if (meta == null) continue; // catalog not synced yet — retried after sync
      // _progressMeta can't rebuild an episode's "S# E# — title" from the local
      // catalog (returns a blank subtitle), so keep the richest label we have:
      // the existing local row, else the server-stored label, else the (blank)
      // reconstructed one. This is what keeps the Continue Watching badge from
      // vanishing on a pulled update or after a reinstall.
      final subtitle = existing != null && existing.subtitle.isNotEmpty
          ? existing.subtitle
          : (r.subtitle.isNotEmpty ? r.subtitle : meta.subtitle);
      await _db.savePosition(
        PlaybackPositionsCompanion.insert(
          sourceId: sourceId,
          kind: ref.kind,
          itemId: ref.itemId,
          seriesId: Value(ref.seriesId),
          title: meta.title,
          subtitle: Value(subtitle),
          imageUrl: Value(meta.imageUrl),
          positionSecs: r.positionSec,
          durationSecs: r.durationSec,
          updatedAt: r.updatedAt,
        ),
        notify: false, // pulled from the server — don't echo it back
      );
    }

    // Push local rows the server is missing or has an older copy of, and
    // drop tombstones for rows the server never had.
    for (final entry in localByToken.entries) {
      final r = remoteByToken[entry.key];
      final p = entry.value;
      if (r == null || p.updatedAt.isAfter(r.updatedAt)) {
        await pushProgress(
          p.kind,
          p.itemId,
          p.seriesId,
          p.positionSecs,
          p.durationSecs,
          subtitle: p.subtitle,
        );
      }
    }
    for (final entry in tombByToken.entries) {
      if (!remoteByToken.containsKey(entry.key)) {
        final t = entry.value;
        await _db.removeTombstone(
          sourceId,
          TombstoneScope.progress,
          t.kind,
          t.itemId,
        );
      }
    }
  }

  // --- Backend reads ---

  Future<List<Map<String, dynamic>>> _fetchRows(String table) async {
    final rows = <Map<String, dynamic>>[];
    const pageSize = 500;
    for (var offset = 0; ; offset += pageSize) {
      final page = await _client.rpc<List<dynamic>>(
        table == 'favorites' ? 'read_favorites' : 'read_progress',
        params: {'page_offset': offset, 'page_size': pageSize},
      );
      rows.addAll(page.cast<Map<String, dynamic>>());
      if (page.length < pageSize) return rows;
    }
  }

  Future<List<_RemoteFavorite>> _fetchFavorites() async => [
    for (final raw in await _fetchRows('favorites'))
      ?_RemoteFavorite.tryParse(raw),
  ];
  Future<List<_RemoteProgress>> _fetchProgress() async => [
    for (final raw in await _fetchRows('watch_progress'))
      ?_RemoteProgress.tryParse(raw),
  ];

  // --- Local metadata resolution (server stores ids only) ---

  Future<_FavoriteMeta?> _favoriteMeta(
    int sourceId,
    CatalogKind kind,
    int id,
  ) async {
    switch (kind) {
      case CatalogKind.live:
        final c = await _db.getLiveChannel(sourceId, id);
        return c == null ? null : _FavoriteMeta(c.name, c.icon);
      case CatalogKind.vod:
        final m = await _db.getMovie(sourceId, id);
        return m == null ? null : _FavoriteMeta(m.name, m.icon);
      case CatalogKind.series:
        final s = await _db.getSeriesItem(sourceId, id);
        return s == null ? null : _FavoriteMeta(s.name, s.cover);
    }
  }

  Future<_ProgressMeta?> _progressMeta(
    int sourceId,
    LocalProgressRef ref,
  ) async {
    switch (ref.kind) {
      case WatchKind.movie:
        final m = await _db.getMovie(sourceId, ref.itemId);
        return m == null ? null : _ProgressMeta(m.name, '', m.icon);
      case WatchKind.episode:
        final s = await _db.getSeriesItem(sourceId, ref.seriesId!);
        // Episode number/title isn't cached; the series name is enough for
        // Continue Watching until the user reopens the series locally.
        return s == null ? null : _ProgressMeta(s.name, '', s.cover);
    }
  }

  Future<void> _swallow(Future<void> Function() op) async {
    try {
      await op();
    } catch (_) {
      // Sync is best-effort; a failed push retries on the next reconcile.
    }
  }
}

class _RemoteFavorite {
  const _RemoteFavorite(this.type, this.itemId, this.createdAt, this.deletedAt);
  final BackendItemType type;
  final String itemId;
  final DateTime createdAt;

  /// Non-null when the server holds a tombstone for this favorite.
  final DateTime? deletedAt;

  static _RemoteFavorite? tryParse(Map<String, dynamic> json) {
    final type = BackendItemType.parse(json['itemType'] as String?);
    final itemId = json['itemId'] as String?;
    final createdAt = DateTime.tryParse((json['createdAt'] as String?) ?? '');
    if (type == null || itemId == null || createdAt == null) return null;
    final deletedRaw = json['deletedAt'] as String?;
    return _RemoteFavorite(
      type,
      itemId,
      createdAt,
      deletedRaw == null ? null : DateTime.tryParse(deletedRaw),
    );
  }
}

class _RemoteProgress {
  const _RemoteProgress({
    required this.type,
    required this.itemId,
    required this.episodeId,
    required this.positionSec,
    required this.durationSec,
    required this.subtitle,
    required this.updatedAt,
    required this.deletedAt,
  });

  final BackendItemType type;
  final String itemId;
  final String episodeId;
  final int positionSec;
  final int durationSec;

  /// Server-stored display label, "" when the server has none.
  final String subtitle;
  final DateTime updatedAt;

  /// Non-null when the server holds a tombstone for this resume point.
  final DateTime? deletedAt;

  String get token => '${type.wire}:$itemId:$episodeId';

  static _RemoteProgress? tryParse(Map<String, dynamic> json) {
    final type = BackendItemType.parse(json['itemType'] as String?);
    final itemId = json['itemId'] as String?;
    final updatedRaw = json['updatedAt'] as String?;
    if (type == null || itemId == null || updatedRaw == null) return null;
    final updatedAt = DateTime.tryParse(updatedRaw);
    if (updatedAt == null) return null;
    final deletedRaw = json['deletedAt'] as String?;
    return _RemoteProgress(
      type: type,
      itemId: itemId,
      episodeId: (json['episodeId'] as String?) ?? '',
      positionSec: (json['positionSec'] as num?)?.toInt() ?? 0,
      durationSec: (json['durationSec'] as num?)?.toInt() ?? 0,
      subtitle: (json['subtitle'] as String?) ?? '',
      updatedAt: updatedAt,
      deletedAt: deletedRaw == null ? null : DateTime.tryParse(deletedRaw),
    );
  }
}

class _FavoriteMeta {
  const _FavoriteMeta(this.name, this.imageUrl);
  final String name;
  final String? imageUrl;
}

class _ProgressMeta {
  const _ProgressMeta(this.title, this.subtitle, this.imageUrl);
  final String title;
  final String subtitle;
  final String? imageUrl;
}
