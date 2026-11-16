import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// Persists resume points: very short media isn't tracked, barely-started
/// playback isn't saved, and nearly-finished items drop off Continue Watching.
class ResumeService {
  ResumeService(this._db, this._sourceId);

  final AppDatabase _db;
  final int _sourceId;

  static const _minDuration = Duration(minutes: 3);
  static const _minPosition = Duration(seconds: 20);
  static const _finishedFraction = 0.95;

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
    if (position < _minPosition || finished) {
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
