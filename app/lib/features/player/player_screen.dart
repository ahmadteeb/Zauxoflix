import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fvp/fvp.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/responsive/form_factor.dart';
import '../../core/app_platform.dart';
import '../../core/theme/app_theme.dart';
import '../../data/backend/backend_providers.dart';
import '../../data/backend/remote_models.dart';
import '../../data/backend/remote_repository.dart';
import '../remote/device_picker.dart';
import '../remote/remote_control_screen.dart';
import '../remote/remote_playback.dart';
import 'player_volume.dart';

class PlayerItem {
  const PlayerItem({
    required this.url,
    required this.title,
    this.subtitle = '',
    this.live = false,
    this.startAt,
    this.identity,
  });

  final String url;
  final String title;
  final String subtitle;
  final bool live;

  /// Resume point — seeked to right after the item opens.
  final Duration? startAt;

  /// Server-side identity, when known — enables casting this item to another
  /// device and lets remotes name what's playing.
  final PlaybackIdentity? identity;
}

typedef PlayerProgressCallback =
    void Function(int index, Duration position, Duration duration);

class PlayerArgs {
  const PlayerArgs({
    required this.items,
    this.initialIndex = 0,
    this.onProgress,
  }) : assert(items.length > 0);

  PlayerArgs.single({
    required String url,
    required String title,
    String subtitle = '',
    bool live = false,
    Duration? startAt,
    PlaybackIdentity? identity,
    this.onProgress,
  }) : items = [
         PlayerItem(
           url: url,
           title: title,
           subtitle: subtitle,
           live: live,
           startAt: startAt,
           identity: identity,
         ),
       ],
       initialIndex = 0;

  final List<PlayerItem> items;
  final int initialIndex;

  /// Reported every few seconds during playback and when an item stops —
  /// callers persist resume points with it. Never fired for live items.
  final PlayerProgressCallback? onProgress;
}

/// Fullscreen playback with custom overlay controls so the same UI works for
/// D-pad, keyboard, touch and mouse. video_player is backed by fvp on desktop
/// and mobile, with platform players on TVs. These backends need custom
/// TV-focus-aware controls. Pops the index of the last played item so callers can sync
/// selection (e.g. live channel list).
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.args});

  final PlayerArgs args;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with WidgetsBindingObserver
    implements RemotePlayerHandle {
  late int _index = widget.args.initialIndex;
  VideoPlayerController? _controller;
  // Guards against a stale async open finishing after a newer one started.
  int _generation = 0;
  // The item the live controller was opened for — _index may already point
  // at the next item while the old controller is being torn down.
  late int _playingIndex = widget.args.initialIndex;

  bool _controlsVisible = true;
  // Desktop-only OS-window fullscreen (see [_toggleFullscreen]). Always false
  // on mobile/TV, where the shell is already immersive.
  bool _fullscreen = false;
  Timer? _hideTimer;
  Timer? _progressTimer;
  // D-pad scrub: rapid arrow presses accumulate into a single target that is
  // committed once the presses stop, so holding the key glides instead of
  // firing one seek per keystroke. Null when not scrubbing.
  Duration? _seekTarget;
  Timer? _seekCommitTimer;
  String? _error;
  bool _autoAdvanced = false;
  // Focused explicitly when playback fails: the screen's key handler normally
  // owns focus, so the retry button would be unreachable by D-pad otherwise.
  final FocusNode _retryFocusNode = FocusNode(debugLabel: 'player-retry');
  // The screen-filling key-handler node. Directional focus search from its
  // full-screen rect never finds the overlay buttons, so arrows explicitly
  // hand focus to _playFocusNode, and hiding the controls hands it back.
  final FocusNode _rootFocusNode = FocusNode(debugLabel: 'player-root');
  final FocusNode _playFocusNode = FocusNode(debugLabel: 'player-play');
  final FocusScopeNode _overlayScope = FocusScopeNode(
    debugLabel: 'player-controls',
  );

  // Cached because dispose runs after the element detaches and ref becomes
  // unusable there (Riverpod forbids it — and a throw in dispose aborts the
  // whole unmount, leaking timers and this handle).
  late final RemotePlaybackController _remotePlayback;

  BoxFit _fit = BoxFit.contain;
  List<(int, String)> _subtitleTracks = const [];
  int? _activeSubtitle;
  List<(int, String)> _audioTracks = const [];
  int? _activeAudio;

  PlayerItem get _item => widget.args.items[_index];
  bool get _hasPrev => _index > 0;
  bool get _hasNext => _index < widget.args.items.length - 1;
  bool get _playlist => widget.args.items.length > 1;

  // fvp track extensions require the mdk backend.
  static final bool _fvpBackend = isFvpPlatform;

  late final bool _lockLandscape =
      !kTvBuild &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_lockLandscape) {
      unawaited(
        SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]),
      );
    }
    WakelockPlus.enable();
    _remotePlayback = ref.read(remotePlaybackProvider.notifier);
    _remotePlayback.attachPlayer(this);
    _openCurrent();
    _scheduleHide();
    if (widget.args.onProgress != null) {
      _progressTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _reportProgress(),
      );
    }
  }

  /// Pushes the current position to the caller (resume persistence).
  void _reportProgress([VideoPlayerController? controller, int? index]) {
    final onProgress = widget.args.onProgress;
    controller ??= _controller;
    index ??= _playingIndex;
    if (onProgress == null || controller == null) return;
    final value = controller.value;
    if (widget.args.items[index].live ||
        !value.isInitialized ||
        value.duration <= Duration.zero) {
      return;
    }
    onProgress(index, value.position, value.duration);
  }

  Future<void> _openCurrent() async {
    final gen = ++_generation;
    final old = _controller;
    if (old != null) {
      _reportProgress(old, _playingIndex);
      old.removeListener(_onControllerChanged);
      setState(() {
        _controller = null;
        _error = null;
        _subtitleTracks = const [];
        _activeSubtitle = null;
        _audioTracks = const [];
        _activeAudio = null;
      });
      // Free the previous stream before opening the next one — panels often
      // allow a single connection.
      await old.dispose();
    }
    if (!mounted || gen != _generation) return;

    // Downloaded items carry a filesystem path instead of a URL.
    final controller = _item.url.startsWith('/')
        ? VideoPlayerController.file(File(_item.url))
        : VideoPlayerController.networkUrl(Uri.parse(_item.url));
    _playingIndex = _index;
    setState(() {
      _controller = controller;
      _error = null;
    });
    controller.addListener(_onControllerChanged);
    try {
      // Store the gain before initialization so a new stream never starts loud.
      await controller.setVolume(ref.read(playerVolumeProvider));
      if (!mounted || gen != _generation) return;
      await controller.initialize();
      if (!mounted || gen != _generation) return;
      if (_fvpBackend) {
        // A generous buffer smooths playback over jittery IPTV connections;
        // live keeps a tighter ceiling so latency stays bounded.
        controller.setBufferRange(
          min: _item.live ? 2000 : 5000,
          max: _item.live ? 10000 : 30000,
        );
      }
      _autoAdvanced = false;
      if (_item.startAt case final startAt? when !_item.live) {
        await controller.seekTo(startAt);
      }
      await controller.play();
      _readTracks(controller);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted && gen == _generation) {
        setState(() => _error = '$e');
        _retryFocusNode.requestFocus();
      }
    }
  }

  void _readTracks(VideoPlayerController controller) {
    if (!_fvpBackend) return;
    try {
      final info = controller.getMediaInfo();
      final subtitles = info?.subtitle ?? const [];
      _subtitleTracks = _labelTracks([for (final s in subtitles) s.metadata]);
      // Subtitles are opt-in: providers routinely ship a forced/default track
      // pre-enabled, so start on Off and let the viewer pick.
      controller.setSubtitleTracks(const []);
      _activeSubtitle = null;

      // A lone audio stream is not a choice — treat it as "no tracks" so the
      // sheet doesn't present a meaningless single entry.
      final audio = info?.audio ?? const [];
      if (audio.length < 2) {
        _audioTracks = const [];
        _activeAudio = null;
      } else {
        final activeAudio = controller.getActiveAudioTracks();
        _audioTracks = _labelTracks([for (final a in audio) a.metadata]);
        _activeAudio = (activeAudio == null || activeAudio.isEmpty)
            ? null
            : activeAudio.first;
      }
    } catch (_) {
      // Extension unavailable — hide the track buttons.
    }
  }

  /// Streams routinely carry several tracks with the same language tag
  /// (normal + SDH/forced, or plain duplicates), which used to render as
  /// "eng, eng, ara, ara". Add the title when it helps, and number the rest.
  static List<(int, String)> _labelTracks(List<Map<String, String>> metadatas) {
    final labels = <String>[];
    for (final (i, meta) in metadatas.indexed) {
      final language = meta['language'];
      final title = meta['title'];
      final label = [
        if (language != null && language.isNotEmpty) language,
        if (title != null && title.isNotEmpty && title != language) title,
      ].join(' — ');
      labels.add(label.isEmpty ? 'Track ${i + 1}' : label);
    }
    final total = <String, int>{};
    for (final label in labels) {
      total[label] = (total[label] ?? 0) + 1;
    }
    final seen = <String, int>{};
    return [
      for (final (i, label) in labels.indexed)
        (
          i,
          total[label]! > 1
              ? '$label (${seen[label] = (seen[label] ?? 0) + 1})'
              : label,
        ),
    ];
  }

  void _selectSubtitle(int? track) {
    final controller = _controller;
    if (controller == null || !_fvpBackend) return;
    try {
      controller.setSubtitleTracks(track == null ? [] : [track]);
      setState(() => _activeSubtitle = track);
    } catch (_) {}
    _showControls();
  }

  void _selectAudio(int track) {
    final controller = _controller;
    if (controller == null || !_fvpBackend) return;
    try {
      controller.setAudioTracks([track]);
      setState(() => _activeAudio = track);
    } catch (_) {}
    _showControls();
  }

  void _onControllerChanged() {
    final value = _controller?.value;
    if (value == null || !mounted) return;
    // Deduped inside the controller — only material transitions go out.
    _remotePlayback.playerChanged();
    if (value.hasError && _error == null) {
      setState(() => _error = value.errorDescription ?? 'Unknown error');
      _retryFocusNode.requestFocus();
      return;
    }
    // Binge flow: roll into the next episode when this one ends.
    if (!_item.live &&
        value.isInitialized &&
        value.isCompleted &&
        _hasNext &&
        !_autoAdvanced) {
      _autoAdvanced = true;
      _goTo(_index + 1);
    }
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.args.items.length) return;
    setState(() => _index = index);
    _showControls();
    _openCurrent();
  }

  /// Backgrounded (TV home button, app switch): stop streaming — panels often
  /// allow a single connection — and persist the resume point. Playback stays
  /// paused on return; `inactive` is ignored so losing window focus on desktop
  /// doesn't interrupt watching.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused || AppLifecycleState.hidden:
        _reportProgress();
        _controller?.pause();
        WakelockPlus.disable();
      case AppLifecycleState.resumed:
        WakelockPlus.enable();
      default:
        break;
    }
  }

  // Detach as soon as the route pops (deactivate precedes dispose by the
  // exit transition) so a relayed command can't hit a dying screen whose
  // Navigator lookup would throw. Re-attach if the element is reparented.
  @override
  void deactivate() {
    _remotePlayback.detachPlayer(this);
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _remotePlayback.attachPlayer(this);
  }

  @override
  void dispose() {
    _remotePlayback.detachPlayer(this);
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _progressTimer?.cancel();
    _seekCommitTimer?.cancel();
    _reportProgress();
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    _retryFocusNode.dispose();
    _rootFocusNode.dispose();
    _playFocusNode.dispose();
    _overlayScope.dispose();
    WakelockPlus.disable();
    if (_lockLandscape) {
      // Browsing has no orientation lock; return control to the device.
      unawaited(SystemChrome.setPreferredOrientations(const []));
    }
    // Don't strand the browse UI fullscreen after leaving the player.
    if (_fullscreen) unawaited(windowManager.setFullScreen(false));
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      // Keep D-pad targets visible, and never steal focus from a track picker.
      if (_overlayScope.hasFocus || !_rootFocusNode.hasFocus) {
        _scheduleHide();
        return;
      }
      setState(() => _controlsVisible = false);
      // Enter must not activate a now-invisible button.
      if (_overlayScope.hasFocus) _rootFocusNode.requestFocus();
    });
  }

  /// Moves D-pad focus from the root node into the controls overlay.
  KeyEventResult _enterControls() {
    if (_controller != null) _playFocusNode.requestFocus();
    _showControls();
    return KeyEventResult.handled;
  }

  void _showControls() {
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;
    controller.value.isPlaying ? controller.pause() : controller.play();
    WakelockPlus.toggle(enable: controller.value.isPlaying);
    _showControls();
  }

  void _seekBy(Duration offset) {
    final controller = _controller;
    if (controller == null || _item.live) return;
    final target = controller.value.position + offset;
    controller.seekTo(target < Duration.zero ? Duration.zero : target);
    _showControls();
  }

  /// D-pad seek: accumulates repeated presses into [_seekTarget] and commits a
  /// single seek once they stop, showing a live preview while scrubbing.
  void _dpadSeek(Duration step) {
    final controller = _controller;
    if (controller == null || _item.live || !controller.value.isInitialized) {
      return;
    }
    final duration = controller.value.duration;
    var target = (_seekTarget ?? controller.value.position) + step;
    if (target < Duration.zero) target = Duration.zero;
    if (target > duration) target = duration;
    setState(() => _seekTarget = target);
    _showControls();
    _seekCommitTimer?.cancel();
    _seekCommitTimer = Timer(const Duration(milliseconds: 500), () {
      final target = _seekTarget;
      if (!mounted || target == null) return;
      _controller?.seekTo(target);
      setState(() => _seekTarget = null);
    });
  }

  void _cycleFit() {
    setState(() {
      _fit = switch (_fit) {
        BoxFit.contain => BoxFit.cover,
        BoxFit.cover => BoxFit.fill,
        _ => BoxFit.contain,
      };
    });
    _showControls();
  }

  String get _fitLabel => switch (_fit) {
    BoxFit.cover => 'Crop',
    BoxFit.fill => 'Stretch',
    _ => 'Fit',
  };

  /// Toggles OS-window fullscreen on desktop. No-op elsewhere: the mobile/TV
  /// shell already runs immersive so there's no window chrome to hide.
  Future<void> _toggleFullscreen() async {
    if (!isDesktopPlatform) return;
    final next = !_fullscreen;
    await windowManager.setFullScreen(next);
    if (!mounted) return;
    setState(() => _fullscreen = next);
    _showControls();
  }

  void _pop() => Navigator.of(context).pop(_index);

  // -- RemotePlayerHandle: transport driven from another device's remote. --

  @override
  RemotePlayerSnapshot remoteSnapshot() {
    final item = widget.args.items[_playingIndex];
    final value = _controller?.value;
    final state = _error != null
        ? 'idle'
        : value == null || !value.isInitialized
        ? 'loading'
        : value.isPlaying
        ? 'playing'
        : 'paused';
    return RemotePlayerSnapshot(
      state: state,
      identity: item.identity,
      title: item.title,
      subtitle: item.subtitle,
      positionSec: item.live ? 0 : (value?.position.inSeconds ?? 0),
      durationSec: item.live ? 0 : (value?.duration.inSeconds ?? 0),
      hasPrev: _playlist && _hasPrev,
      hasNext: _playlist && _hasNext,
    );
  }

  @override
  void remotePause() {
    if (_controller?.value.isPlaying ?? false) _togglePlay();
  }

  @override
  void remoteResume() {
    final value = _controller?.value;
    if (value != null && value.isInitialized && !value.isPlaying) _togglePlay();
  }

  @override
  void remoteSeek(Duration position) {
    if (_item.live) return;
    _controller?.seekTo(position);
  }

  @override
  void remoteNext() {
    if (_hasNext) _goTo(_index + 1);
  }

  @override
  void remotePrev() {
    if (_hasPrev) _goTo(_index - 1);
  }

  @override
  void remoteStop() {
    if (mounted) _pop();
  }

  /// Hands the current item off to another device, then swaps this screen for
  /// the remote control.
  Future<void> _cast() async {
    _showControls();
    final identity = _item.identity;
    if (identity == null) return;
    final device = await showRemoteDevicePicker(context, ref);
    if (device == null || !mounted) return;
    final positionSec = _item.live
        ? 0
        : (_controller?.value.position.inSeconds ?? 0);
    try {
      await ref
          .read(remoteRepositoryProvider)
          .play(
            targetDeviceId: device.deviceId,
            identity: identity,
            positionSec: positionSec,
          );
    } on RemoteException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
      return;
    }
    if (!mounted) return;
    // Persist the local resume point, then let the remote take over — the
    // local stream is released by this screen's dispose.
    _reportProgress();
    context.pushReplacement('/remote', extra: RemoteControlArgs(device));
  }

  void _handleBack() {
    if (_fullscreen) {
      _toggleFullscreen();
    } else if (_controlsVisible && _overlayScope.hasFocus) {
      setState(() => _controlsVisible = false);
      _rootFocusNode.requestFocus();
    } else {
      _pop();
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event is KeyRepeatEvent &&
        const [
          LogicalKeyboardKey.escape,
          LogicalKeyboardKey.goBack,
          LogicalKeyboardKey.select,
          LogicalKeyboardKey.enter,
          LogicalKeyboardKey.space,
          LogicalKeyboardKey.mediaPlayPause,
          LogicalKeyboardKey.keyF,
        ].contains(event.logicalKey)) {
      return KeyEventResult.handled;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape || LogicalKeyboardKey.goBack:
        _handleBack();
      case LogicalKeyboardKey.keyF when isDesktopPlatform:
        _toggleFullscreen();
      case LogicalKeyboardKey.space || LogicalKeyboardKey.mediaPlayPause:
        _togglePlay();
      case LogicalKeyboardKey.select || LogicalKeyboardKey.enter:
        // Let a focused control or error button take Enter/Select.
        if (_error != null ||
            (_controlsVisible && FocusManager.instance.primaryFocus != node)) {
          return KeyEventResult.ignored;
        }
        _togglePlay();
      case LogicalKeyboardKey.mediaRewind:
        _seekBy(const Duration(seconds: -10));
      case LogicalKeyboardKey.mediaFastForward:
        _seekBy(const Duration(seconds: 10));
      case LogicalKeyboardKey.arrowLeft:
        if (_error != null) return KeyEventResult.ignored;
        if (_controlsVisible) {
          if (_rootFocusNode.hasPrimaryFocus) return _enterControls();
          // Focus is on a control: keep controls up while navigating and let
          // the default directional action move between the buttons.
          _showControls();
          return KeyEventResult.ignored;
        }
        _dpadSeek(const Duration(seconds: -10));
      case LogicalKeyboardKey.arrowRight:
        if (_error != null) return KeyEventResult.ignored;
        if (_controlsVisible) {
          if (_rootFocusNode.hasPrimaryFocus) return _enterControls();
          _showControls();
          return KeyEventResult.ignored;
        }
        _dpadSeek(const Duration(seconds: 10));
      case LogicalKeyboardKey.mediaTrackPrevious ||
          LogicalKeyboardKey.channelDown:
        if (_hasPrev) _goTo(_index - 1);
      case LogicalKeyboardKey.mediaTrackNext || LogicalKeyboardKey.channelUp:
        if (_hasNext) _goTo(_index + 1);
      case LogicalKeyboardKey.arrowDown || LogicalKeyboardKey.arrowUp:
        if (_controlsVisible) {
          if (_rootFocusNode.hasPrimaryFocus) return _enterControls();
          _showControls();
          return KeyEventResult.ignored;
        }
        return _enterControls();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Widget _buildVideo(VideoPlayerController controller, VideoPlayerValue value) {
    final ar = value.aspectRatio > 0 ? value.aspectRatio : 16 / 9;
    // Size the video box explicitly per fit mode against the real screen size,
    // rather than relying on value.size (which fvp can report as zero for some
    // streams, leaving cover/fill visually identical to fit).
    return LayoutBuilder(
      builder: (context, constraints) {
        final sw = constraints.maxWidth;
        final sh = constraints.maxHeight;
        final screenAr = sh > 0 ? sw / sh : ar;
        final double w;
        final double h;
        switch (_fit) {
          case BoxFit.fill: // Stretch — distort to fill the screen.
            w = sw;
            h = sh;
          case BoxFit.cover: // Crop — fill the screen, overflow clipped.
            (w, h) = ar > screenAr ? (sh * ar, sh) : (sw, sw / ar);
          default: // Fit — whole frame, letterboxed.
            (w, h) = ar > screenAr ? (sw, sw / ar) : (sh * ar, sh);
        }
        return ClipRect(
          child: Center(
            child: SizedBox(
              width: w,
              height: h,
              child: VideoPlayer(controller),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _handleBack();
        },
        child: Focus(
          focusNode: _rootFocusNode,
          autofocus: true,
          onKeyEvent: _onKey,
          child: MouseRegion(
            onHover: (_) => _showControls(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _controlsVisible ? _togglePlay() : _showControls(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (controller != null)
                    ValueListenableBuilder(
                      valueListenable: controller,
                      builder: (context, value, _) {
                        if (!value.isInitialized) {
                          return const _StatusIndicator(label: 'Loading…');
                        }
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildVideo(controller, value),
                            if (value.isBuffering && !value.isCompleted)
                              const _StatusIndicator(label: 'Buffering…'),
                          ],
                        );
                      },
                    )
                  else if (_error == null)
                    const _StatusIndicator(label: 'Loading…'),
                  if (_error != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 40,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Playback failed: $_error',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FilledButton.icon(
                                  focusNode: _retryFocusNode,
                                  onPressed: _openCurrent,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                  ),
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Retry'),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: _pop,
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Back'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_seekTarget case final target? when controller != null)
                    _SeekPreview(target: target, controller: controller),
                  IgnorePointer(
                    ignoring: !_controlsVisible,
                    child: AnimatedOpacity(
                      opacity: _controlsVisible ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: FocusScope(
                        node: _overlayScope,
                        child: _ControlsOverlay(
                          controller: controller,
                          volume: ref.watch(playerVolumeProvider),
                          onVolumeChanged: (volume) {
                            ref.read(playerVolumeProvider.notifier).set(volume);
                            unawaited(_controller?.setVolume(volume));
                            _showControls();
                          },
                          playFocusNode: _playFocusNode,
                          title: _item.title,
                          subtitle: _item.subtitle,
                          live: _item.live,
                          hasPrev: _playlist && _hasPrev,
                          hasNext: _playlist && _hasNext,
                          fitLabel: _fitLabel,
                          subtitleTracks: _subtitleTracks,
                          activeSubtitle: _activeSubtitle,
                          audioTracks: _audioTracks,
                          activeAudio: _activeAudio,
                          onBack: _pop,
                          onCast: !kTvBuild && _item.identity != null
                              ? _cast
                              : null,
                          onTogglePlay: _togglePlay,
                          onSeekBy: _seekBy,
                          onPrev: () => _goTo(_index - 1),
                          onNext: () => _goTo(_index + 1),
                          onCycleFit: _cycleFit,
                          showFullscreen: isDesktopPlatform,
                          fullscreen: _fullscreen,
                          onToggleFullscreen: _toggleFullscreen,
                          onSelectSubtitle: _selectSubtitle,
                          onSelectAudio: _selectAudio,
                          onInteraction: _showControls,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({
    required this.controller,
    required this.playFocusNode,
    required this.volume,
    required this.onVolumeChanged,
    required this.title,
    required this.subtitle,
    required this.live,
    required this.hasPrev,
    required this.hasNext,
    required this.fitLabel,
    required this.subtitleTracks,
    required this.activeSubtitle,
    required this.audioTracks,
    required this.activeAudio,
    required this.onBack,
    required this.onCast,
    required this.onTogglePlay,
    required this.onSeekBy,
    required this.onPrev,
    required this.onNext,
    required this.onCycleFit,
    required this.showFullscreen,
    required this.fullscreen,
    required this.onToggleFullscreen,
    required this.onSelectSubtitle,
    required this.onSelectAudio,
    required this.onInteraction,
  });

  final VideoPlayerController? controller;
  final FocusNode playFocusNode;
  final double volume;
  final ValueChanged<double> onVolumeChanged;
  final String title;
  final String subtitle;
  final bool live;
  final bool hasPrev;
  final bool hasNext;
  final String fitLabel;
  final List<(int, String)> subtitleTracks;
  final int? activeSubtitle;
  final List<(int, String)> audioTracks;
  final int? activeAudio;
  final VoidCallback onBack;
  final VoidCallback? onCast;
  final VoidCallback onTogglePlay;
  final void Function(Duration) onSeekBy;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onCycleFit;

  /// Desktop-only OS-window fullscreen toggle.
  final bool showFullscreen;
  final bool fullscreen;
  final VoidCallback onToggleFullscreen;
  final ValueChanged<int?> onSelectSubtitle;
  final ValueChanged<int> onSelectAudio;
  final VoidCallback onInteraction;

  Future<void> _pickSubtitle(BuildContext context) async {
    onInteraction();
    final picked = await showModalBottomSheet<(int?,)>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Text(
                'Subtitles',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              autofocus: activeSubtitle == null,
              title: const Text('Off'),
              trailing: activeSubtitle == null
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(const (null,)),
            ),
            if (subtitleTracks.isEmpty)
              const ListTile(
                enabled: false,
                title: Text('No subtitles available'),
              ),
            for (final (track, label) in subtitleTracks)
              ListTile(
                autofocus: activeSubtitle == track,
                title: Text(label),
                trailing: activeSubtitle == track
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop((track,)),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onSelectSubtitle(picked.$1);
  }

  Future<void> _pickAudio(BuildContext context) async {
    onInteraction();
    final picked = await showModalBottomSheet<(int,)>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Text(
                'Audio',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            if (audioTracks.isEmpty)
              const ListTile(
                enabled: false,
                title: Text('No audio tracks available'),
              ),
            for (final (track, label) in audioTracks)
              ListTile(
                autofocus:
                    activeAudio == track ||
                    (activeAudio == null && track == audioTracks.first.$1),
                title: Text(label),
                trailing: activeAudio == track
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop((track,)),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onSelectAudio(picked.$1);
  }

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    final safeTop = MediaQuery.paddingOf(context).top;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Column(
      children: [
        // Top bar: back + title.
        Container(
          padding: EdgeInsets.fromLTRB(16, 12 + safeTop, 16, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_rounded, size: 28),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (live) const _LiveBadge(),
              if (onCast != null)
                IconButton(
                  onPressed: onCast,
                  tooltip: 'Play on another device',
                  icon: const Icon(Icons.cast_rounded, size: 26),
                ),
            ],
          ),
        ),
        const Spacer(),
        // Bottom bar: transport + progress + secondary controls.
        Container(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 14 + safeBottom),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!live && controller != null)
                _ProgressBar(controller: controller, onSeeked: onInteraction),
              LayoutBuilder(
                builder: (context, constraints) {
                  final transport = Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (hasPrev || hasNext)
                        IconButton(
                          onPressed: hasPrev ? onPrev : null,
                          tooltip: live ? 'Previous channel' : 'Previous',
                          icon: const Icon(
                            Icons.skip_previous_rounded,
                            size: 34,
                          ),
                        ),
                      if (!live)
                        IconButton(
                          tooltip: 'Rewind 10 seconds',
                          onPressed: () =>
                              onSeekBy(const Duration(seconds: -10)),
                          icon: const Icon(Icons.replay_10_rounded, size: 32),
                        ),
                      const SizedBox(width: 12),
                      if (controller != null)
                        ValueListenableBuilder(
                          valueListenable: controller,
                          builder: (context, value, _) => IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              fixedSize: const Size(64, 64),
                              padding: const EdgeInsets.all(12),
                            ),
                            focusNode: playFocusNode,
                            onPressed: onTogglePlay,
                            tooltip: value.isPlaying ? 'Pause' : 'Play',
                            iconSize: 36,
                            icon: Icon(
                              value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 68, height: 68),
                      const SizedBox(width: 12),
                      if (!live)
                        IconButton(
                          tooltip: 'Forward 30 seconds',
                          onPressed: () =>
                              onSeekBy(const Duration(seconds: 30)),
                          icon: const Icon(Icons.forward_30_rounded, size: 32),
                        ),
                      if (hasPrev || hasNext)
                        IconButton(
                          onPressed: hasNext ? onNext : null,
                          tooltip: live ? 'Next channel' : 'Next',
                          icon: const Icon(Icons.skip_next_rounded, size: 34),
                        ),
                    ],
                  );
                  final tracks = Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      IconButton(
                        onPressed: () => _pickAudio(context),
                        tooltip: 'Audio',
                        icon: const Icon(Icons.audiotrack_rounded, size: 26),
                      ),
                      IconButton(
                        onPressed: () => _pickSubtitle(context),
                        tooltip: 'Subtitles',
                        icon: Icon(
                          activeSubtitle == null
                              ? Icons.subtitles_off_outlined
                              : Icons.subtitles_rounded,
                          size: 26,
                          color: activeSubtitle == null
                              ? null
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  );
                  final display = Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      PlayerVolumeButton(
                        volume: volume,
                        onChanged: onVolumeChanged,
                        onInteraction: onInteraction,
                      ),
                      TextButton.icon(
                        onPressed: onCycleFit,
                        icon: const Icon(
                          Icons.aspect_ratio_rounded,
                          size: 24,
                          color: Colors.white,
                        ),
                        label: Text(
                          fitLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (showFullscreen)
                        IconButton(
                          onPressed: onToggleFullscreen,
                          tooltip: fullscreen
                              ? 'Exit fullscreen (F)'
                              : 'Fullscreen (F)',
                          icon: Icon(
                            fullscreen
                                ? Icons.fullscreen_exit_rounded
                                : Icons.fullscreen_rounded,
                            size: 28,
                          ),
                        ),
                    ],
                  );
                  final stacked =
                      constraints.maxWidth < 1100 ||
                      MediaQuery.textScalerOf(context).scale(14) > 20;
                  return stacked
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(child: transport),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: tracks),
                                const SizedBox(width: 16),
                                Expanded(child: display),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: tracks),
                            const SizedBox(width: 24),
                            transport,
                            const SizedBox(width: 24),
                            Expanded(child: display),
                          ],
                        );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

String _fmtClock(Duration d) {
  final h = d.inHours;
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.controller, required this.onSeeked});

  final VideoPlayerController controller;
  final VoidCallback onSeeked;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) {
        final position = value.position;
        final duration = value.duration;
        final max = duration.inMilliseconds.toDouble();
        // Buffered ahead of the playhead — the furthest range end covers it.
        final buffered = value.buffered.isEmpty
            ? Duration.zero
            : value.buffered.last.end;
        return Row(
          children: [
            Text(
              _fmtClock(position),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  activeTrackColor: AppColors.primary,
                  thumbColor: AppColors.primary,
                  inactiveTrackColor: Colors.white24,
                  secondaryActiveTrackColor: Colors.white54,
                ),
                child: Slider(
                  value: max > 0
                      ? position.inMilliseconds.clamp(0, max.toInt()).toDouble()
                      : 0,
                  secondaryTrackValue: max > 0
                      ? buffered.inMilliseconds.clamp(0, max.toInt()).toDouble()
                      : null,
                  max: max > 0 ? max : 1,
                  onChanged: max > 0
                      ? (v) {
                          controller.seekTo(Duration(milliseconds: v.round()));
                          onSeeked();
                        }
                      : null,
                ),
              ),
            ),
            Text(
              _fmtClock(duration),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Centered pill shown while D-pad scrubbing: target time and jump direction.
class _SeekPreview extends StatelessWidget {
  const _SeekPreview({required this.target, required this.controller});

  final Duration target;
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) {
        final forward = target >= value.position;
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  forward
                      ? Icons.fast_forward_rounded
                      : Icons.fast_rewind_rounded,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  '${_fmtClock(target)} / ${_fmtClock(value.duration)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
