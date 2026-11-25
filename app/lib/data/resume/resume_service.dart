import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../xtream/xtream_models.dart';
import 'series_order.dart';

/// Persists resume points: very short media isn't tracked, barely-started
/// playback isn't saved, and nearly-finished items drop off Continue Watching.
class ResumeService {
  ResumeService(this._db, this._sourceId);

  final AppDatabase _db;
  final int _sourceId;

  static const _minDuration = Duration(minutes: 3);
  static const _minPosition = Duration(seconds: 20);
  static const _finishedFraction = 0.95;

  /// A full-duration episode is a caught-up checkpoint. A zero-duration
  /// successor is a playable suggestion until it earns a real resume point.
  Future<void> completeEpisode({
    required int seriesId,
    required int episodeId,
    required String title,
    required String finishedSubtitle,
    required int finishedDuration,
    int? nextId,
    String subtitle = '',
    String? imageUrl,
    String? containerExtension,
    PlaybackPosition? expectedCheckpoint,
  }) => _db.transaction(() async {
    final source = await (_db.select(
      _db.sources,
    )..where((s) => s.id.equals(_sourceId))).getSingleOrNull();
    if (source == null) return;
    if (expectedCheckpoint != null) {
      final latest = await _db.latestSeriesPosition(_sourceId, seriesId);
      if (latest != expectedCheckpoint) return;
    }
    if (expectedCheckpoint == null) {
      await _db.recordWatched(_sourceId, CatalogKind.series, seriesId);
    }
    await _db.recordWatchedEpisode(_sourceId, episodeId);
    if (nextId == null || nextId == episodeId) {
      await _db.savePosition(
        PlaybackPositionsCompanion.insert(
          sourceId: _sourceId,
          kind: WatchKind.episode,
          itemId: episodeId,
          seriesId: Value(seriesId),
          title: title,
          subtitle: Value(finishedSubtitle),
          imageUrl: Value(imageUrl),
          positionSecs: finishedDuration,
          durationSecs: finishedDuration,
          updatedAt: DateTime.now(),
        ),
      );
      return;
    }
    await _db.deletePosition(_sourceId, WatchKind.episode, episodeId);
    final row =
        await (_db.select(_db.playbackPositions)..where(
              (p) =>
                  p.sourceId.equals(_sourceId) &
                  p.kind.equalsValue(WatchKind.episode) &
                  p.itemId.equals(nextId),
            ))
            .getSingleOrNull();
    final partial = row != null && !row.isCompletedEpisode ? row : null;
    await _db.savePosition(
      PlaybackPositionsCompanion.insert(
        sourceId: _sourceId,
        kind: WatchKind.episode,
        itemId: nextId,
        seriesId: Value(seriesId),
        title: title,
        subtitle: Value(subtitle),
        imageUrl: Value(imageUrl ?? row?.imageUrl),
        containerExtension: Value(
          containerExtension ?? row?.containerExtension,
        ),
        positionSecs: partial?.positionSecs ?? 0,
        durationSecs: partial?.durationSecs ?? 0,
        updatedAt: DateTime.now(),
      ),
    );
  });

  /// Check only followed series with a saved finale, sequentially and in
  /// bounded batches. Recheck the checkpoint in the transaction after HTTP.
  Future<void> refreshCaughtUp(
    Future<XtreamSeriesInfo> Function(int) fetchSeries,
    Map<int, DateTime> lastChecks, {
    required bool Function() active,
  }) async {
    final now = DateTime.now();
    final markers = await _db.caughtUpEpisodes(_sourceId);
    final cutoff = now.subtract(const Duration(hours: 6));
    final rows =
        markers.where((p) {
          final checked = lastChecks[p.seriesId!];
          return checked == null || !checked.isAfter(cutoff);
        }).toList()..sort(
          (a, b) => (lastChecks[a.seriesId]?.millisecondsSinceEpoch ?? 0)
              .compareTo(lastChecks[b.seriesId]?.millisecondsSinceEpoch ?? 0),
        );
    final seriesSeen = <int>{};
    for (final row in rows) {
      if (!active() || seriesSeen.length >= 8) return;
      final series = row.seriesId!;
      if (!seriesSeen.add(series)) continue;
      lastChecks[series] = now;
      if (await _db.latestSeriesPosition(_sourceId, series) != row) continue;
      try {
        final info = await fetchSeries(series);
        if (!active()) return;
        final next = nextCatalogEpisode(
          info,
          row.itemId,
          lastLabel: row.subtitle,
        );
        if (next == null) continue;
        final e = next.$1[next.$2];
        await completeEpisode(
          seriesId: series,
          episodeId: row.itemId,
          title: row.title,
          finishedSubtitle: row.subtitle,
          finishedDuration: row.durationSecs,
          nextId: e.id,
          subtitle: 'S${e.season} E${e.episodeNum} — ${e.title}',
          imageUrl: row.imageUrl ?? e.image,
          containerExtension: e.containerExtension,
          expectedCheckpoint: row,
        );
      } catch (_) {
        // Brief provider outages can retry on the next scheduled sweep.
        lastChecks[series] = now.subtract(
          const Duration(hours: 5, minutes: 45),
        );
      }
    }
  }

  Future<void> report({
    required WatchKind kind,
    required int itemId,
    int? seriesId,
    required String title,
    String subtitle = '',
    String? imageUrl,
    String? containerExtension,
    required Duration position,
    required Duration duration,
  }) async {
    if (duration < _minDuration) return;
    final finished =
        position.inMilliseconds >= duration.inMilliseconds * _finishedFraction;
    if (kind == WatchKind.episode && seriesId != null) {
      // The player replaces a completed episode with its successor atomically.
      // An initial tick on that successor must retain its queued bookmark.
      if (position < _minPosition || position >= duration) return;
    } else if (kind == WatchKind.movie && finished) {
      await _db.transaction(() async {
        final source = await (_db.select(
          _db.sources,
        )..where((s) => s.id.equals(_sourceId))).getSingleOrNull();
        if (source == null) return;
        await _db.recordWatched(_sourceId, CatalogKind.vod, itemId);
        await _db.deletePosition(_sourceId, kind, itemId);
      });
      return;
    } else if (position < _minPosition || finished) {
      await _db.deletePosition(_sourceId, kind, itemId);
      return;
    }
    await _db.savePosition(
      PlaybackPositionsCompanion.insert(
        sourceId: _sourceId,
        kind: kind,
        itemId: itemId,
        seriesId: Value(seriesId),
        title: title,
        subtitle: Value(subtitle),
        imageUrl: Value(imageUrl),
        containerExtension: Value(containerExtension),
        positionSecs: position.inSeconds,
        durationSecs: duration.inSeconds,
        updatedAt: DateTime.now(),
      ),
    );
  }
}
