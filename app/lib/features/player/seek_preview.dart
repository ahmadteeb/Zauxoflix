import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fvp/fvp.dart';
import 'package:video_player/video_player.dart';

import '../../core/app_platform.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/media_artwork.dart';
import 'seek_thumbnail_track.dart';

String playbackClock(Duration duration) {
  final hours = duration.inHours;
  final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

/// Uses the playback decoder's rendered frames and provider image manifests.
/// Remote video is never reopened to generate a thumbnail.
class SeekPreviewMedia extends ChangeNotifier {
  SeekPreviewMedia(this.controller) {
    if (isFvpPlatform) controller.addListener(_capture);
  }

  final VideoPlayerController controller;
  final _frames = <int, ({Duration time, ui.Image image})>{};
  Dio? _http;
  SeekThumbnailTrack? _track;
  bool _requested = false;
  bool _capturing = false;
  bool _captureUnavailable = false;
  bool _disposed = false;

  SeekThumbnail? thumbnailAt(Duration time) => _track?.at(time);
  ({Duration time, ui.Image image})? frameAt(Duration time) {
    final frame = _frames[time.inSeconds ~/ 8];
    return frame != null &&
            (frame.time - time).abs() <= const Duration(seconds: 3)
        ? frame
        : null;
  }

  String? get localPath =>
      isFvpPlatform && controller.dataSourceType == DataSourceType.file
      ? Uri.tryParse(controller.dataSource)?.toFilePath()
      : null;

  void request() {
    if (_requested || controller.dataSourceType != DataSourceType.network) {
      return;
    }
    final uri = Uri.tryParse(controller.dataSource);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        !uri.path.toLowerCase().endsWith('.m3u8')) {
      return;
    }
    _requested = true;
    unawaited(_loadTrack(uri));
  }

  Future<void> _loadTrack(Uri uri) async {
    final http = _http = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ),
    );
    Future<(Uri, String)> get(Uri url) async {
      final response = await http.getUri<ResponseBody>(
        url,
        options: Options(responseType: ResponseType.stream),
      );
      final bytes = <int>[];
      await for (final chunk in response.data!.stream) {
        if (bytes.length + chunk.length > 512 * 1024) {
          throw const FormatException('Preview playlist too large');
        }
        bytes.addAll(chunk);
      }
      return (response.realUri, utf8.decode(bytes, allowMalformed: true));
    }

    try {
      final (master, text) = await get(uri);
      final images = SeekThumbnailTrack.imagePlaylist(text, master);
      if (images == null || _disposed) return;
      final (playlist, content) = await get(images);
      if (_disposed) return;
      _track = SeekThumbnailTrack.parse(content, playlist);
      if (_track != null) notifyListeners();
    } on Exception {
      // A missing image track must never affect playback or prevent seeking.
    } finally {
      http.close(force: true);
      if (identical(_http, http)) _http = null;
    }
  }

  void _capture() {
    final value = controller.value;
    if (_disposed ||
        _capturing ||
        _captureUnavailable ||
        !value.isInitialized ||
        value.isBuffering ||
        value.duration <= Duration.zero ||
        value.size.isEmpty) {
      return;
    }
    final time = value.position;
    if (time <= Duration.zero) return;
    final bucket = time.inSeconds ~/ 8;
    if (_frames[bucket] != null) return;
    unawaited(_snapshot(time, bucket));
  }

  Future<void> _snapshot(Duration time, int bucket) async {
    _capturing = true;
    try {
      const width = 160;
      final aspect = controller.value.aspectRatio.clamp(.75, 3.0);
      final height = (width / aspect).round();
      final raw = await controller
          .snapshot(width: width, height: height)
          .timeout(const Duration(milliseconds: 750), onTimeout: () => null);
      if (raw == null ||
          _disposed ||
          raw.length != width * height * 4 ||
          (controller.value.position - time).abs() >
              const Duration(seconds: 1)) {
        return;
      }
      final decoded = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        raw,
        width,
        height,
        ui.PixelFormat.rgba8888,
        decoded.complete,
      );
      final image = await decoded.future;
      if (_disposed) {
        image.dispose();
        return;
      }
      if (_frames.length >= 36) {
        _frames.remove(_frames.keys.first)?.image.dispose();
      }
      _frames[bucket] = (time: time, image: image);
      notifyListeners();
    } on StateError {
      // The registered backend does not export snapshots.
      _captureUnavailable = true;
    } on Exception {
      // Native snapshot failure is independent of playback.
    } finally {
      _capturing = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    controller.removeListener(_capture);
    _http?.close(force: true);
    for (final frame in _frames.values) {
      frame.image.dispose();
    }
    super.dispose();
  }
}

class SeekPreviewCard extends StatelessWidget {
  const SeekPreviewCard({
    super.key,
    required this.media,
    required this.target,
    required this.origin,
    required this.title,
    this.artwork,
  });

  final SeekPreviewMedia media;
  final Duration target, origin;
  final String title;
  final String? artwork;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Material(
      color: AppColors.surface,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: LayoutBuilder(
              builder: (context, bounds) => ListenableBuilder(
                listenable: media,
                builder: (context, _) {
                  final width = bounds.maxWidth;
                  final height = bounds.maxHeight;
                  final thumbnail = media.thumbnailAt(target);
                  final frame = media.frameAt(target);
                  return Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.hardEdge,
                    children: [
                      MediaArtwork(
                        url: artwork,
                        title: title,
                        icon: Icons.movie_outlined,
                        kind: ArtworkKind.episode,
                        cacheWidth: 320,
                        hasCaption: false,
                      ),
                      const PositionedDirectional(
                        top: 6,
                        start: 6,
                        child: _PreviewImageLabel('Artwork'),
                      ),
                      if (frame != null)
                        RawImage(image: frame.image, fit: BoxFit.cover),
                      if (frame != null &&
                          frame.time.inSeconds != target.inSeconds)
                        PositionedDirectional(
                          top: 6,
                          start: 6,
                          child: _PreviewImageLabel(
                            'Frame at ${playbackClock(frame.time)}',
                          ),
                        ),
                      if (thumbnail != null)
                        Positioned(
                          left: -width * thumbnail.column,
                          top: -height * thumbnail.row,
                          width: width * thumbnail.columns,
                          height: height * thumbnail.rows,
                          child: Image.network(
                            thumbnail.uri.toString(),
                            fit: BoxFit.fill,
                            cacheWidth: (width * thumbnail.columns * 1.5)
                                .ceil()
                                .clamp(1, 2048),
                            cacheHeight: (height * thumbnail.rows * 1.5)
                                .ceil()
                                .clamp(1, 2048),
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      if (media.localPath case final path?)
                        _LocalFrame(path: path, target: target),
                    ],
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  target < origin
                      ? Icons.fast_rewind_rounded
                      : Icons.fast_forward_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    playbackClock(target),
                    key: const ValueKey('seek-preview-time'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontFeatures: [ui.FontFeature.tabularFigures()],
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _PreviewImageLabel extends StatelessWidget {
  const _PreviewImageLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
    ),
  );
}

/// A tiny, muted, paused decoder for offline files. Opening a network
/// source here would compete with playback for the provider's stream slot.
class _LocalFrame extends StatefulWidget {
  const _LocalFrame({required this.path, required this.target});

  final String path;
  final Duration target;

  @override
  State<_LocalFrame> createState() => _LocalFrameState();
}

class _LocalFrameState extends State<_LocalFrame> {
  late final VideoPlayerController _controller;
  Timer? _delay;
  Duration? _rendered;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(
      File(widget.path),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize().timeout(const Duration(seconds: 4));
      if (!mounted) return;
      await _controller.setVolume(0);
      if (mounted) _schedule();
    } on Exception {
      // The title artwork remains visible when the file cannot be opened.
    }
  }

  @override
  void didUpdateWidget(_LocalFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) _schedule();
  }

  void _schedule() {
    _delay?.cancel();
    _delay = Timer(const Duration(milliseconds: 140), _render);
  }

  Future<void> _render() async {
    if (!mounted || _busy || !_controller.value.isInitialized) return;
    _busy = true;
    final target = widget.target;
    try {
      await _controller.seekTo(target);
      if (mounted) setState(() => _rendered = target);
    } on Exception {
      // A failed sample is simply skipped.
    } finally {
      _busy = false;
      if (mounted && widget.target != target) _schedule();
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_rendered != widget.target) return const SizedBox.shrink();
    final size = _controller.value.size;
    if (size.isEmpty) return const SizedBox.shrink();
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: VideoPlayer(_controller),
      ),
    );
  }
}
