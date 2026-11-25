import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:video_player/video_player.dart';

import '../../data/db/app_database.dart';

/// Accumulates only the time the live decoder spends playing in the foreground.
/// An injected monotonic clock keeps the qualification rules testable.
class LiveWatchTime {
  Duration? _started;
  Duration _elapsed = Duration.zero;
  int _reported = 0;

  Duration elapsed(Duration now) =>
      _elapsed + (_started == null ? Duration.zero : now - _started!);

  void setPlaying(bool playing, Duration now) {
    if (playing) {
      _started ??= now;
    } else if (_started != null) {
      _elapsed += now - _started!;
      _started = null;
    }
  }

  int takeQualifiedSeconds(Duration now) {
    final total = elapsed(now).inSeconds;
    if (total < 30) return 0;
    final unreported = total - _reported;
    _reported = total;
    return unreported;
  }
}

class LiveWatchTracker {
  LiveWatchTracker(
    this.controller,
    this.db,
    this.sourceId,
    this.viewer,
    this.streamId,
    this.key,
  ) {
    controller.addListener(_update);
    _update();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _checkpoint());
  }

  final VideoPlayerController controller;
  final AppDatabase db;
  final int sourceId, streamId;
  final String viewer;
  final String? key;
  final _clock = Stopwatch()..start();
  final _time = LiveWatchTime();
  late final Timer _timer;
  bool _success = false;

  void _update() {
    final value = controller.value;
    _time.setPlaying(
      value.isInitialized &&
          value.isPlaying &&
          !value.isBuffering &&
          !value.hasError,
      _clock.elapsed,
    );
  }

  void _checkpoint() {
    final now = _clock.elapsed;
    if (!_success && key != null && _time.elapsed(now).inSeconds >= 3) {
      _success = true;
      db
          .saveLiveTuning(sourceId, viewer, key!, successful: Value(streamId))
          .ignore();
    }
    final seconds = _time.takeQualifiedSeconds(now);
    if (seconds > 0) {
      db
          .addLiveViewing(sourceId, viewer, streamId, DateTime.now(), seconds)
          .ignore();
    }
  }

  void dispose() {
    _timer.cancel();
    controller.removeListener(_update);
    _time.setPlaying(false, _clock.elapsed);
    _checkpoint();
  }
}
