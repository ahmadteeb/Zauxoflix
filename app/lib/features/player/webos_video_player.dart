import 'package:flutter/services.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:video_player_webos/video_player_webos.dart';

/// The TV owns the audio volume. video_player applies its default gain during
/// initialization, even when the app never calls setVolume itself.
class WebOsVideoPlayer extends VideoPlayerWebOs {
  static void registerWith() {
    VideoPlayerPlatform.instance = WebOsVideoPlayer();
  }

  // video_player completes its creation barrier only when create returns.
  // Deliver an open error on the normal event stream so dispose and Retry
  // also work when the platform fails before allocating a texture.
  int _nextFailedId = -2;
  final _failedOpens = <int, PlatformException>{};

  @override
  Future<int?> create(DataSource dataSource) async {
    try {
      return await super.create(dataSource);
    } on Exception {
      final id = _nextFailedId--;
      _failedOpens[id] = PlatformException(
        code: 'open',
        message: 'Unable to open the media stream',
      );
      return id;
    }
  }

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    final failure = _failedOpens[textureId];
    return failure == null
        ? super.videoEventsFor(textureId)
        : Stream.error(failure);
  }

  @override
  Future<void> dispose(int textureId) async {
    if (_failedOpens.remove(textureId) == null) await super.dispose(textureId);
  }

  @override
  Future<void> setVolume(int textureId, double volume) async {}
}
