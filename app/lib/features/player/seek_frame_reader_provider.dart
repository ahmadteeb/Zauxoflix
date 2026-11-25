import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import 'android_seek_frames.dart';
import 'playback_seek_frames.dart';
import 'seek_frames.dart';
import 'webos_seek_frames.dart';

final seekFrameReaderProvider =
    Provider<SeekFrameReader Function(VideoPlayerController)>((ref) {
      if (Platform.isAndroid) {
        return (controller) => AndroidSeekFrameReader(
          controller.dataSource,
          controller.httpHeaders,
        );
      }
      return (controller) => WebOsSeekFrameReader(controller.dataSource);
    });

final playbackSeekFramesProvider =
    Provider<PlaybackSeekFrames? Function(VideoPlayerController)>((ref) {
      return (controller) => Platform.isAndroid
          ? PlaybackSeekFrameSource(controller).capture
          : null;
    });
