import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:fvp/fvp.dart';

import '../../core/app_platform.dart';
import '../../data/db/app_database.dart';
import '../live/live_watch_tracker.dart';

import 'playback_recovery.dart';

final playbackHandoffProvider = Provider((_) => PlaybackHandoff());

/// The preview and fullscreen routes share the provider's single stream slot.
class PlaybackHandoff {
  PlaybackSession? _current;
  PlaybackRecovery? _recovery;
  final _budget = PlaybackRetryBudget();

  PlaybackRecovery begin({
    required String url,
    required bool live,
    required bool webOs,
    required void Function() reopen,
    required void Function(String) onFailure,
  }) {
    _recovery?.dispose();
    return _recovery = PlaybackRecovery(
      url: url,
      budget: _budget,
      live: live,
      webOs: webOs,
      reopen: reopen,
      onFailure: onFailure,
    );
  }

  Future<void> _closing = Future.value();

  void end(PlaybackRecovery recovery) {
    recovery.dispose();
    if (identical(_recovery, recovery)) _recovery = null;
  }

  PlaybackSession select(VideoPlayerController controller) {
    _current?.close();
    return _current = PlaybackSession._(this, controller);
  }
}

class PlaybackSession {
  PlaybackSession._(this._handoff, this.controller);

  final PlaybackHandoff _handoff;
  final VideoPlayerController controller;
  final _ready = Completer<bool>();
  Timer? _deadline;
  LiveWatchTracker? _watch;
  bool get current => identical(_handoff._current, this);

  void trackLive(
    AppDatabase db,
    int sourceId,
    String viewer,
    int streamId,
    String? channelKey,
  ) {
    if (current) {
      _watch ??= LiveWatchTracker(
        controller,
        db,
        sourceId,
        viewer,
        streamId,
        channelKey,
      );
    }
  }

  Future<bool> initialize({required bool live, double? volume}) {
    _deadline = Timer(const Duration(seconds: 30), () {
      _ready.completeError(
        TimeoutException('The stream took too long to open.'),
      );
      close();
    });
    unawaited(_open(volume, live));
    return _ready.future;
  }

  Future<void> _open(double? volume, bool live) async {
    try {
      await _handoff._closing;
      if (!current) return;
      if (volume != null) await controller.setVolume(volume);
      if (!current) return;
      await controller.initialize();
      if (!current) return;
      if (isFvpPlatform) {
        try {
          controller.setBufferRange(
            min: live ? 2000 : 5000,
            max: live ? 10000 : 30000,
          );
        } on StateError {
          // A replacement platform implementation can use its own buffer policy.
        }
      }
      _ready.complete(true);
    } catch (error, stack) {
      if (current) _ready.completeError(error, stack);
    } finally {
      _deadline?.cancel();
    }
  }

  void close() {
    if (!current) return;
    _watch?.dispose();
    _watch = null;
    _handoff._current = null;
    _deadline?.cancel();
    if (!_ready.isCompleted) _ready.complete(false);
    final previous = _handoff._closing;
    _handoff._closing = previous.then<void>(
      (_) => controller.dispose(),
      onError: (Object _, StackTrace _) => controller.dispose(),
    );
    // An unmount may have no successor to await this future.
    _handoff._closing.ignore();
  }
}
