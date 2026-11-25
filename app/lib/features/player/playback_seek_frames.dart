import 'dart:async';
import 'dart:typed_data';

import 'package:fvp/fvp.dart';
import 'package:video_player/video_player.dart';

import 'seek_frames.dart';

/// Capture the active video output once its native playback clock reaches the
/// seek. The controller's ValueNotifier reports the target on submission and
/// cannot tell us when the decoder has actually arrived there.
class PlaybackSeekFrameSource {
  PlaybackSeekFrameSource(this.controller);

  final VideoPlayerController controller;

  Future<void> capture(
    Duration target,
    bool Function() isCurrent,
    void Function(int slot, DecodedSeekFrame frame) onFrame,
  ) async {
    const poll = Duration(milliseconds: 20);
    const early = Duration(milliseconds: 85);
    const late = Duration(milliseconds: 285);
    final elapsed = Stopwatch()..start();
    Duration? previous;
    var slot = 1;
    while (isCurrent() && elapsed.elapsed < const Duration(seconds: 4)) {
      if (!controller.value.isInitialized || controller.value.hasError) return;
      try {
        final position = await controller.position;
        if (!isCurrent() || position == null) return;
        final value = controller.value;
        final expected = slot == 1
            ? target
            : target + const Duration(seconds: 1);
        if (expected >= value.duration || (slot == 2 && !value.isPlaying)) {
          return;
        }
        final advancing = previous != null && position > previous;
        final settled =
            previous != null &&
            (value.isPlaying ? advancing : elapsed.elapsed >= poll);
        previous = value.isBuffering ? null : position;
        if (position > expected + late) {
          // Don't pass an unrelated picture off as the requested frame.
          if (slot == 2) return;
          slot = 2;
        } else if (!value.isBuffering &&
            settled &&
            position >= expected - early) {
          final pixels = await controller
              .snapshot(width: seekFrameWidth, height: seekFrameHeight)
              .timeout(const Duration(milliseconds: 450));
          if (!isCurrent()) return;
          final after = await controller.position;
          if (!isCurrent() || after == null) return;
          if (pixels != null &&
              pixels.length == seekFrameWidth * seekFrameHeight * 4 &&
              after >= expected - early &&
              after <= expected + late) {
            onFrame(slot, DecodedSeekFrame(position, _snapshotBitmap(pixels)));
            if (slot == 2) return;
            slot = 2;
          }
        }
      } on Exception {
        return;
      } on StateError {
        return;
      }
      await Future<void>.delayed(poll);
    }
  }
}

Uint8List _snapshotBitmap(Uint8List rgba) {
  final bgr = Uint8List(seekFrameByteCount);
  for (var source = 0, target = 0; target < bgr.length; source += 4) {
    bgr[target++] = rgba[source + 2];
    bgr[target++] = rgba[source + 1];
    bgr[target++] = rgba[source];
  }
  return seekFrameBitmap(bgr);
}
