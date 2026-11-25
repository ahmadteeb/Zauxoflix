import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fvp/fvp.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:video_player_webos/video_player_webos.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/responsive/form_factor.dart';
import '../../core/app_platform.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_sheet.dart';
import '../../data/backend/backend_providers.dart';
import '../../data/live/live_providers.dart';
import '../../data/providers.dart';
import '../../data/resume/series_order.dart';
import '../../data/backend/remote_models.dart';
import '../../data/backend/remote_repository.dart';
import '../../data/downloads/download_manager.dart';
import '../../data/xtream/xtream_models.dart';
import '../remote/cast_session.dart';
import '../shell/navigation_glass.dart';
import '../remote/device_picker.dart';
import 'player_browse_panel.dart';
import 'player_catalog.dart';
import '../remote/remote_control_screen.dart';
import '../remote/remote_playback.dart';
import 'playback_handoff.dart';
import 'playback_recovery.dart';
import 'player_volume.dart';
import 'autoplay_preference.dart';
import 'episode_end_card.dart';
import 'episode_buffer.dart';
import 'seek_filmstrip.dart';
import 'seek_frame_reader_provider.dart';
import 'seek_frames.dart';
import 'seek_preview.dart';

const playerDetailsOrigin = 'in-player-details';

class PlayerItem {
  const PlayerItem({
    required this.url,
    required this.title,
    this.subtitle = '',
    this.live = false,
    this.startAt,
    this.identity,
    this.episodeImage,
    this.seriesCover,
    this.containerExtension,
    this.liveLogo,
    this.liveStationKey,
    this.liveVersion,
    this.liveAlternate,
  });

  final String url;
  final String? episodeImage, seriesCover, containerExtension;
  final String title;
  final String subtitle;
  final bool live;
  final String? liveLogo, liveStationKey, liveVersion;
  final PlayerItem? liveAlternate;

  /// Resume point — seeked to right after the item opens.
  final Duration? startAt;

  /// Server-side identity, when known — enables casting this item to another
  /// device and lets remotes name what's playing.
  final PlaybackIdentity? identity;

  PlayerItem withStartAt(Duration? start) => PlayerItem(
    url: url,
    title: title,
    subtitle: subtitle,
    live: live,
    identity: identity,
    episodeImage: episodeImage,
    seriesCover: seriesCover,
    containerExtension: containerExtension,
    liveLogo: liveLogo,
    liveStationKey: liveStationKey,
    liveVersion: liveVersion,
    liveAlternate: liveAlternate,
    startAt: start,
  );
}

typedef PlayerProgressCallback =
    void Function(int index, Duration position, Duration duration);

class PlayerArgs {
  const PlayerArgs({
    required this.items,
    this.initialIndex = 0,
    this.returnChannelId = false,
    this.onProgress,
  }) : assert(items.length > 0);

  PlayerArgs.single({
    required String url,
    required String title,
    String subtitle = '',
    bool live = false,
    String? liveLogo,
    Duration? startAt,
    PlaybackIdentity? identity,
    this.onProgress,
  }) : items = [
         PlayerItem(
           url: url,
           title: title,
           subtitle: subtitle,
           live: live,
           liveLogo: liveLogo,
           startAt: startAt,
           identity: identity,
         ),
       ],
       initialIndex = 0,
       returnChannelId = false;

  final List<PlayerItem> items;
  final int initialIndex;
  final bool returnChannelId;

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
  late PlayerArgs _queue = widget.args;
  late PlayerArgs _playingQueue = _queue;
  late int _index = _queue.initialIndex;
  final _panelMemory = PlayerPanelMemory();
  bool _detailsOpen = false;
  bool _resumeAfterDetails = false;
  bool _browserOpen = false;
  bool _leaving = false;
  VideoPlayerController? _controller;
  PlaybackSession? _session;
  late final PlaybackHandoff _handoff;
  late PlaybackRecovery _recovery;
  bool _wantPlay = true;
  bool _background = false;
  bool _recordedLive = false;
  Duration? _lastPosition;
  double? _decoderAspect;
  bool _positionReady = false;
  Duration _lastDuration = Duration.zero;
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
  Duration? _previewTarget;
  Duration? _previewOrigin;
  bool _draggingTimeline = false;
  Timer? _seekCommitTimer;
  Timer? _seekBufferTimer;
  Timer? _previewTimer;
  Future<void> _seekInFlight = Future.value();
  Duration? _previewResolved;
  String? _error;
  VideoPlayerController? _endedController;
  (PlayerArgs, int)? _nextEpisode;
  String? _endViewer;
  int? _endSource;
  int _episodeGeneration = 0;
  bool _endCardVisible = false;
  bool _countdownCancelled = false;
  bool _findingNext = false;
  int _endSeconds = 3;
  bool _episodeFinished = false;
  bool _endDismissed = false;
  PlayerItem? _transitionItem;
  PlayerItem? _progressCompletedItem;
  Future<(PlayerArgs, int)?>? _nextLookup;
  bool _jumpingEpisode = false;
  final _endScope = FocusScopeNode();
  final _endActionFocus = FocusNode(debugLabel: 'episode-end-action');
  // Focused explicitly when playback fails: the screen's key handler normally
  // owns focus, so the retry button would be unreachable by D-pad otherwise.
  final FocusNode _retryFocusNode = FocusNode(debugLabel: 'player-retry');
  // The screen-filling key-handler node. Directional focus search from its
  // full-screen rect never finds the overlay buttons, so arrows explicitly
  // hand focus to _playFocusNode, and hiding the controls hands it back.
  final FocusNode _rootFocusNode = FocusNode(debugLabel: 'player-root');
  final FocusNode _playFocusNode = FocusNode(debugLabel: 'player-play');
  final FocusNode _timelineFocus = FocusNode(debugLabel: 'player-timeline');
  FocusNode? _timelineReturnFocus;
  final FocusNode _rewindFocus = FocusNode(debugLabel: 'player-rewind');
  final FocusNode _forwardFocus = FocusNode(debugLabel: 'player-forward');
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

  PlayerItem get _item => _queue.items[_index];
  bool get _hasCatalogId => int.tryParse(_item.identity?.itemId ?? '') != null;
  bool get _hasPrev => _index > 0;
  bool get _hasNext => _index < _queue.items.length - 1;
  bool get _playlist => _queue.items.length > 1;
  bool get _isTv => ref.read(formFactorOverrideProvider)?.isTv ?? kTvBuild;

  VideoPlayerWebOs? get _webOsVideo {
    final platform = VideoPlayerPlatform.instance;
    return platform is VideoPlayerWebOs ? platform : null;
  }

  bool get _usesFrameStrip => Platform.isAndroid || _webOsVideo != null;

  // fvp track extensions require the mdk backend.
  static final bool _fvpBackend = isFvpPlatform;

  Orientation? _lockedOrientation;

  void _rotatePlayer() {
    final target = MediaQuery.orientationOf(context) == Orientation.portrait
        ? Orientation.landscape
        : Orientation.portrait;
    setState(() => _lockedOrientation = target);
    unawaited(
      SystemChrome.setPreferredOrientations(
        target == Orientation.portrait
            ? const [DeviceOrientation.portraitUp]
            : const [
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ],
      ),
    );
    _showControls();
  }

  void _followDeviceRotation() {
    setState(() => _lockedOrientation = null);
    unawaited(SystemChrome.setPreferredOrientations(const []));
    _showControls();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setWakelock(true);
    _remotePlayback = ref.read(remotePlaybackProvider.notifier);
    _remotePlayback.attachPlayer(this);
    _handoff = ref.read(playbackHandoffProvider);
    _openCurrent();
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _background = true;
      _pausePlayback();
    }
    _scheduleHide();
    if (!_item.live) {
      _progressTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _reportProgress(),
      );
    }
  }

  /// Pushes the current position to the caller (resume persistence).
  void _reportProgress([VideoPlayerController? controller, int? index]) {
    final onProgress = _playingQueue.onProgress;
    controller ??= _controller;
    index ??= _playingIndex;
    if (onProgress == null || controller == null) return;
    final value = controller.value;
    if (identical(_progressCompletedItem, _playingQueue.items[index]) ||
        _playingQueue.items[index].live ||
        !_positionReady ||
        !value.isInitialized ||
        value.duration <= Duration.zero) {
      return;
    }
    onProgress(index, value.position, value.duration);
  }

  void _beginRecovery() {
    _recovery = _handoff.begin(
      url: _item.url,
      live: _item.live,
      webOs: isWebOsPlatform,
      reopen: () => unawaited(_openDecoder()),
      onFailure: _playbackFailed,
    );
  }

  void _playbackFailed(String reason) {
    if (!mounted || !_wantPlay) return;
    if (_item.liveAlternate case final alternate?
        when !_background && !_leaving && !_detailsOpen && !_browserOpen) {
      _queue = PlayerArgs(
        items: [..._queue.items]..[_index] = alternate,
        initialIndex: _index,
        returnChannelId: _queue.returnChannelId,
        onProgress: _queue.onProgress,
      );
      _goTo(_index);
      return;
    }
    _controller?.removeListener(_onControllerChanged);
    _session?.close();
    setState(() {
      _transitionItem = null;
      _controller = null;
      _error = reason;
    });
    if (!_browserOpen && !_detailsOpen) _retryFocusNode.requestFocus();
    _remotePlayback.playerChanged();
  }

  Future<void> _openCurrent() {
    _resetEpisodeEnd();
    _wantPlay = true;
    _beginRecovery();
    _subtitleTracks = const [];
    _activeSubtitle = null;
    _audioTracks = const [];
    _activeAudio = null;
    return _openDecoder();
  }

  Future<void> _openDecoder() async {
    _seekCommitTimer?.cancel();
    _seekBufferTimer?.cancel();
    _previewTimer?.cancel();
    _seekTarget = null;
    _previewTarget = null;
    _previewOrigin = null;
    _previewResolved = null;
    _seekInFlight = Future.value();
    final recovery = _recovery;
    final liveId = _item.live && _item.identity?.itemType == 'LIVE'
        ? int.tryParse(_item.identity!.itemId)
        : null;
    final sourceId = liveId == null
        ? null
        : ref.read(activeSourceProvider).value?.id;
    final old = _controller;
    if (old != null) {
      if (!old.value.hasError) _reportProgress(old, _playingIndex);
      old.removeListener(_onControllerChanged);

      // Free the previous stream before opening the next one — panels often
      // allow a single connection.
      _session?.close();
    }

    // Downloaded items carry a filesystem path instead of a URL.
    final uri = Uri.parse(_item.url);
    final bytes = old is BufferedEpisodeController
        ? old.buffer.takePrepared(uri)
        : null;
    final controller = File(_item.url).isAbsolute && !uri.hasAuthority
        ? VideoPlayerController.file(File(_item.url))
        : _item.identity?.itemType == 'SERIES' &&
              ref.read(episodeBufferEnabledProvider) &&
              bufferableEpisode(uri)
        ? BufferedEpisodeController(uri, prefix: bytes)
        : VideoPlayerController.networkUrl(uri);
    final session = _session = _handoff.select(controller);
    _playingQueue = _queue;
    _playingIndex = _index;
    _progressCompletedItem = null;
    _decoderAspect = null;
    _positionReady = false;
    setState(() {
      _controller = controller;
      _error = null;
    });
    controller.addListener(_onControllerChanged);
    try {
      final ready = await session.initialize(
        live: _item.live,
        volume: isWebOsPlatform ? null : ref.read(playerVolumeProvider),
      );
      if (!ready || !mounted || !session.current) return;
      if ((_lastPosition ?? _item.startAt) case final startAt?
          when !_item.live) {
        try {
          await controller.seekTo(startAt);
        } on PlatformException catch (error) {
          if (error.code != 'seek_unavailable') rethrow;
          if (mounted && session.current) _showSeekUnavailable();
        }
      }
      if (!session.current || !_wantPlay) return;
      _positionReady = true;
      await controller.play();
      if (!session.current || !_wantPlay) return;
      recovery.playing(controller.value);
      if (sourceId != null && liveId != null && mounted) {
        final viewer = ref.read(liveViewerProvider);
        if (viewer != null) {
          final stationKey =
              _item.liveStationKey ??
              ref
                  .read(liveDirectoryProvider(sourceId))
                  .value
                  ?.byStream[liveId]
                  ?.key;
          session.trackLive(
            ref.read(databaseProvider),
            sourceId,
            viewer,
            liveId,
            stationKey,
          );
        }
      }
      if (!_recordedLive &&
          liveId != null &&
          sourceId != null &&
          mounted &&
          !controller.value.hasError) {
        _recordedLive = true;
        ref
            .read(databaseProvider)
            .recordLivePlayback(sourceId, liveId)
            .ignore();
      }
      _readTracks(controller);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted && identical(_session, session)) {
        recovery.failure(e);
      }
    }
  }

  void _readTracks(VideoPlayerController controller) {
    if (!_fvpBackend) return;
    try {
      final subtitleLabel = _subtitleTracks
          .where((t) => t.$1 == _activeSubtitle)
          .firstOrNull
          ?.$2;
      final audioLabel = _audioTracks
          .where((t) => t.$1 == _activeAudio)
          .firstOrNull
          ?.$2;
      final info = controller.getMediaInfo();
      final subtitles = info?.subtitle ?? const [];
      _subtitleTracks = _labelTracks([for (final s in subtitles) s.metadata]);
      // Subtitles are opt-in: providers routinely ship a forced/default track
      // pre-enabled, so start on Off and let the viewer pick.
      _activeSubtitle = _subtitleTracks
          .where((t) => t.$2 == subtitleLabel)
          .firstOrNull
          ?.$1;
      controller.setSubtitleTracks([?_activeSubtitle]);

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
        final restored = _audioTracks
            .where((t) => t.$2 == audioLabel)
            .firstOrNull;
        if (restored != null) {
          controller.setAudioTracks([restored.$1]);
          _activeAudio = restored.$1;
        }
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
    if (value == null || !mounted || _session?.current != true) return;
    if (value.isInitialized) {
      _decoderAspect = value.aspectRatio;
      if (value.duration > Duration.zero) _lastDuration = value.duration;
    }
    if (!_playingQueue.items[_playingIndex].live &&
        _positionReady &&
        value.isInitialized &&
        !value.hasError) {
      _lastPosition = value.position;
    }
    if (_transitionItem != null &&
        _positionReady &&
        value.isPlaying &&
        !value.isBuffering &&
        value.position >
            (_item.startAt ?? Duration.zero) +
                const Duration(milliseconds: 100)) {
      setState(() => _transitionItem = null);
    }
    _recovery.observe(value);
    // Deduped inside the controller — only material transitions go out.
    _remotePlayback.playerChanged();
    if (value.hasError) return;
    if (_item.live || !value.isInitialized || value.duration <= Duration.zero) {
      return;
    }
    final finished = value.isCompleted && !value.isPlaying;
    if (finished && !_episodeFinished && !_wantPlay) _countdownCancelled = true;
    if (finished && _wantPlay) {
      setState(() => _wantPlay = false);
      _setWakelock(false);
    }
    if (_item.identity?.itemType != 'SERIES' || !_positionReady || _leaving) {
      return;
    }
    final remaining = value.duration - value.position;
    if (!finished && remaining > const Duration(seconds: 15)) {
      if (_endedController != null) {
        final cancelled = _countdownCancelled;
        setState(() {
          _resetEpisodeEnd();
          _countdownCancelled = cancelled;
        });
        _cancelPrebuffer();
      }
      return;
    }
    if (_endedController != _controller) {
      _endedController = _controller;
      final auth = ref.read(authControllerProvider);
      _endViewer = auth is Authenticated ? auth.user.id : null;
      _endSource = ref.read(activeSourceProvider).value?.id;
      setState(() => _findingNext = true);
      final generation = _episodeGeneration;
      final lookup = _nextLookup = _resolveNextEpisode();
      unawaited(
        lookup.then(
          (next) {
            if (_sameEpisode(generation)) {
              setState(() {
                _findingNext = false;
                _nextEpisode = next;
              });
            }
          },
          onError: (Object _) {
            if (_sameEpisode(generation)) setState(() => _findingNext = false);
          },
        ),
      );
    }
    final seconds = (remaining.inMilliseconds / 1000).ceil().clamp(1, 3);
    final visible =
        !_endDismissed && (finished || remaining <= const Duration(seconds: 3));
    if (_episodeFinished != finished ||
        _endCardVisible != visible ||
        _endSeconds != seconds) {
      setState(() {
        _endSeconds = seconds;
        _episodeFinished = finished;
        _endCardVisible = visible;
      });
      if (finished) _recordEpisodeCompletion();
    }
    final next = _nextEpisode;
    final controller = _controller;
    if (!finished &&
        _wantPlay &&
        !_countdownCancelled &&
        _endViewer != null &&
        next != null &&
        controller is BufferedEpisodeController &&
        !value.isBuffering &&
        _canAdvanceEpisode() &&
        ref.read(autoplayPreferenceProvider(_endViewer!)).value == true) {
      controller.buffer.prepare(Uri.parse(next.$1.items[next.$2].url));
    }
  }

  void _cancelPrebuffer() {
    final controller = _controller;
    if (controller is BufferedEpisodeController) {
      controller.buffer.cancelPrepared();
    }
  }

  void _resetEpisodeEnd() {
    _episodeGeneration++;
    _draggingTimeline = false;
    _endedController = null;
    _episodeFinished = false;
    _endDismissed = false;
    _endCardVisible = false;
    _countdownCancelled = false;
    _findingNext = false;
    _nextEpisode = null;
    _nextLookup = null;
  }

  bool _sameEpisode(int generation) =>
      mounted &&
      !_leaving &&
      generation == _episodeGeneration &&
      _endedController == _controller &&
      _session?.current == true &&
      ref.read(activeSourceProvider).value?.id == _endSource;

  bool _canAdvanceEpisode() {
    if (!_sameEpisode(_episodeGeneration) ||
        _background ||
        _detailsOpen ||
        _browserOpen ||
        _draggingTimeline ||
        _seekTarget != null ||
        ModalRoute.of(context)?.isCurrent != true) {
      return false;
    }
    final auth = ref.read(authControllerProvider);
    return (auth is Authenticated ? auth.user.id : null) == _endViewer;
  }

  Future<(PlayerArgs, int)?> _resolveNextEpisode() async {
    final identity = _item.identity!;
    if (_hasNext &&
        _queue.items[_index + 1].identity?.itemType == 'SERIES' &&
        _queue.items[_index + 1].identity?.itemId == identity.itemId) {
      return (_queue, _index + 1);
    }
    final source = _endSource;
    final seriesId = int.tryParse(identity.itemId);
    final episodeId = int.tryParse(identity.episodeId ?? '');
    final api = ref.read(xtreamApiProvider);
    if (source == null ||
        seriesId == null ||
        episodeId == null ||
        api == null) {
      throw StateError('Series order unavailable');
    }
    // Capture the source-scoped dependencies before awaiting. A confirmed
    // completion can finish saving the successor after the viewer goes Home.
    final db = ref.read(databaseProvider);
    final resume = ref.read(resumeServiceProvider);
    final downloads = ref.read(downloadManagerProvider.notifier);
    final info = await ref.read(playerSeriesProvider(seriesId).future);
    if (!info.seasons.values.any(
      (season) => season.any((e) => e.id == episodeId),
    )) {
      throw StateError('Episode order unavailable');
    }
    final next = nextCatalogEpisode(info, episodeId);
    if (next == null) return null;
    final series = await db.getSeriesItem(source, seriesId);
    if (series == null) throw StateError('Series unavailable');
    final args = seasonPlayback(api, series, next.$1, next.$2, resume);
    final local = await preferLocalDownloads(downloads, source, args);
    return (local, local.initialIndex);
  }

  (List<XtreamEpisode>, int)? _adjacentCatalogEpisode(
    XtreamSeriesInfo? info, {
    required bool previous,
  }) {
    final id = int.tryParse(_item.identity?.episodeId ?? '');
    if (id == null || info == null) return null;
    return previous
        ? previousCatalogEpisode(info, id)
        : nextCatalogEpisode(info, id);
  }

  Future<void> _jumpEpisode({required bool previous}) async {
    if (_leaving || _jumpingEpisode) return;
    if (previous ? _hasPrev : _hasNext) {
      _goTo(_index + (previous ? -1 : 1));
      return;
    }
    if (!previous && _episodeFinished && _nextEpisode != null) {
      _playNextEpisode();
      return;
    }
    final current = _item;
    final seriesId = int.tryParse(current.identity?.itemId ?? '');
    final source = ref.read(activeSourceProvider).value?.id;
    final api = ref.read(xtreamApiProvider);
    if (current.identity?.itemType != 'SERIES' ||
        seriesId == null ||
        source == null ||
        api == null) {
      return;
    }
    final model = _adjacentCatalogEpisode(
      ref.read(playerSeriesProvider(seriesId)).value,
      previous: previous,
    );
    if (model == null) return;
    final db = ref.read(databaseProvider);
    final resume = ref.read(resumeServiceProvider);
    final downloads = ref.read(downloadManagerProvider.notifier);
    _jumpingEpisode = true;
    try {
      final series = await db.getSeriesItem(source, seriesId);
      if (series == null) return;
      final args = await preferLocalDownloads(
        downloads,
        source,
        seasonPlayback(api, series, model.$1, model.$2, resume),
      );
      if (!mounted ||
          _leaving ||
          !identical(_item, current) ||
          ref.read(activeSourceProvider).value?.id != source) {
        return;
      }
      _queue = args;
      _goTo(args.initialIndex);
    } on Exception {
      if (mounted && !_leaving && identical(_item, current)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open this episode.')),
        );
      }
    } finally {
      _jumpingEpisode = false;
    }
  }

  void _recordEpisodeCompletion() {
    final item = _item;
    if (identical(_progressCompletedItem, item) ||
        !_sameEpisode(_episodeGeneration)) {
      return;
    }
    final series = int.tryParse(item.identity?.itemId ?? '');
    final episode = int.tryParse(item.identity?.episodeId ?? '');
    final lookup = _nextLookup;
    final resume = ref.read(resumeServiceProvider);
    if (series == null || episode == null || lookup == null || resume == null) {
      return;
    }
    _progressCompletedItem = item;
    final duration = _lastDuration.inSeconds.clamp(1, 1 << 31);
    unawaited(
      lookup
          .catchError((Object _) => null)
          .then((result) async {
            final next = result == null ? null : result.$1.items[result.$2];
            await resume.completeEpisode(
              seriesId: series,
              episodeId: episode,
              title: item.title,
              finishedSubtitle: item.subtitle,
              finishedDuration: duration,
              nextId: int.tryParse(next?.identity?.episodeId ?? ''),
              subtitle: next?.subtitle ?? '',
              imageUrl:
                  next?.seriesCover ?? item.seriesCover ?? next?.episodeImage,
              containerExtension: next?.containerExtension,
            );
          })
          .catchError((Object _) {
            // Closing a source also closes its local progress store.
          }),
    );
  }

  void _playNextEpisode() {
    final next = _nextEpisode;
    if (next == null || !_canAdvanceEpisode()) return;
    _recordEpisodeCompletion();
    _queue = next.$1;
    _transitionItem = _queue.items[next.$2];
    _goTo(next.$2);
  }

  void _cancelCountdown() {
    _cancelPrebuffer();
    if (_endedController != null && !_countdownCancelled) {
      setState(() => _countdownCancelled = true);
    }
  }

  void _goTo(int index, {bool replay = false}) {
    if (_background ||
        _detailsOpen ||
        index < 0 ||
        index >= _queue.items.length) {
      return;
    }
    _lastPosition = replay ? Duration.zero : null;
    _lastDuration = Duration.zero;
    _recordedLive = false;
    _seekCommitTimer?.cancel();
    _seekTarget = null;
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
        _background = true;
        _cancelCountdown();
        _resumeAfterDetails = false;
        _reportProgress();
        _pausePlayback();
        _setWakelock(false);
      case AppLifecycleState.resumed:
        _background = false;
        _setWakelock(_wantPlay);
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
    _seekBufferTimer?.cancel();
    _previewTimer?.cancel();
    _reportProgress();
    _controller?.removeListener(_onControllerChanged);
    _handoff.end(_recovery);
    _session?.close();
    _endScope.dispose();
    _endActionFocus.dispose();
    _retryFocusNode.dispose();
    _rootFocusNode.dispose();
    _playFocusNode.dispose();
    _timelineFocus.dispose();
    _rewindFocus.dispose();
    _forwardFocus.dispose();
    _overlayScope.dispose();
    _setWakelock(false);
    if (_lockedOrientation != null) {
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
      if (!_rootFocusNode.hasFocus ||
          _draggingTimeline ||
          _seekTarget != null ||
          (_usesFrameStrip && _previewTarget != null) ||
          (_isTv &&
              (_timelineFocus.hasFocus ||
                  _rewindFocus.hasFocus ||
                  _forwardFocus.hasFocus)) ||
          (!_isTv && _overlayScope.hasFocus)) {
        _scheduleHide();
        return;
      }
      if (_overlayScope.hasFocus) _rootFocusNode.requestFocus();
      setState(() => _controlsVisible = false);
    });
  }

  /// Moves D-pad focus from the root node into the controls overlay.
  KeyEventResult _enterControls() {
    if (_error == null) {
      _overlayScope.descendantsAreFocusable = true;
      _playFocusNode.requestFocus();
    }
    _showControls();
    return KeyEventResult.handled;
  }

  void _leaveTimeline() {
    final previous = _timelineReturnFocus;
    if (previous != null &&
        previous.context != null &&
        previous.canRequestFocus) {
      previous.requestFocus();
    } else {
      _playFocusNode.requestFocus();
    }
    _showControls();
  }

  void _showControls() {
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  void _togglePlay() {
    if (_error != null) return;
    _wantPlay ? _pausePlayback() : remoteResume();
    _showControls();
  }

  void _pausePlayback() {
    _cancelPrebuffer();
    setState(() {
      _transitionItem = null;
      _wantPlay = false;
    });
    if (_background || _detailsOpen) _dismissVideoPreview();
    _handoff.end(_recovery);
    final controller = _controller;
    if (controller != null &&
        _positionReady &&
        !controller.value.hasError &&
        controller.value.isInitialized) {
      unawaited(controller.pause());
    } else {
      controller?.removeListener(_onControllerChanged);
      _session?.close();
      setState(() => _controller = null);
    }
    _setWakelock(false);
    _remotePlayback.playerChanged();
  }

  void _setWakelock(bool enabled) {
    // Screen inhibition is optional: a desktop session may have no portal.
    if (!isWebOsPlatform) WakelockPlus.toggle(enable: enabled).ignore();
  }

  void _seekBy(Duration offset) {
    final controller = _controller;
    if (controller == null) return;
    _seekTo(
      (_seekTarget ?? controller.value.position) + offset,
      debounce: _isTv,
    );
    _showControls();
  }

  void _dpadSeek(Duration step) {
    final controller = _controller;
    if (controller == null) return;
    _seekTo((_seekTarget ?? controller.value.position) + step, debounce: true);
    _showControls();
  }

  void _showSeekUnavailable() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Unable to seek in this stream.')),
      );
  }

  void _dismissVideoPreview() {
    if (_webOsVideo == null || _previewTarget == null) return;
    _seekCommitTimer?.cancel();
    _previewTimer?.cancel();
    setState(() {
      _seekTarget = null;
      _previewTarget = null;
      _previewResolved = null;
    });
  }

  void _hidePreviewAfter(Duration delay) {
    _previewTimer?.cancel();
    _previewTimer = Timer(delay, () {
      if (!mounted || _draggingTimeline) return;
      setState(() => _previewTarget = _previewResolved = null);
    });
  }

  void _previewFramesResolved(Duration target) {
    _previewResolved = target;
    if (_previewTarget == target && _seekTarget == null) {
      _hidePreviewAfter(const Duration(milliseconds: 1850));
    }
  }

  void _decodeAndroidSeekImmediately(VideoPlayerController controller) {
    if (!Platform.isAndroid || !_fvpBackend) return;
    controller.setBufferRange(min: 0);
    _seekBufferTimer?.cancel();
    _seekBufferTimer = Timer(const Duration(seconds: 2), () {
      if (identical(_controller, controller) &&
          controller.value.isInitialized) {
        controller.setBufferRange();
      }
    });
  }

  void _seekTo(Duration position, {bool debounce = false}) {
    final controller = _controller;
    final webOs = _webOsVideo;
    if (controller == null ||
        _item.live ||
        !controller.value.isInitialized ||
        controller.value.duration <= Duration.zero ||
        (webOs != null && (!_positionReady || _background))) {
      return;
    }
    final target = Duration(
      milliseconds: position.inMilliseconds.clamp(
        0,
        controller.value.duration.inMilliseconds - (webOs == null ? 0 : 1),
      ),
    );
    if (webOs != null && _previewTarget == target) {
      if (_seekTarget == null && !_draggingTimeline) {
        _hidePreviewAfter(
          _previewResolved == target
              ? const Duration(milliseconds: 1850)
              : const Duration(seconds: 9),
        );
      }
      return;
    }
    final origin = _seekTarget ?? controller.value.position;
    _previewTimer?.cancel();
    setState(() {
      _seekTarget = target;
      _previewTarget = target;
      _previewOrigin = origin;
      if (_previewResolved != target) _previewResolved = null;
    });
    _seekCommitTimer?.cancel();
    bool current() =>
        mounted &&
        !_leaving &&
        identical(controller, _controller) &&
        identical(target, _seekTarget);
    // A slow native seek must finish before applying the most recent input.
    // Pointer, transport and remote commands can each replace a pending scrub.
    void commit() {
      _seekInFlight = _seekInFlight.then((_) async {
        if (!current()) return;
        try {
          // webOS keeps the newest pending seek while the decoder is busy.
          // Wait for command submission so input can keep replacing that slot.
          _decodeAndroidSeekImmediately(controller);
          await controller.seekTo(target);
        } on Exception {
          if (!current()) return;
          _showSeekUnavailable();
          setState(
            () => _seekTarget = _previewTarget = _previewResolved = null,
          );
          return;
        }
        if (current()) {
          setState(() => _seekTarget = null);
          _hidePreviewAfter(
            !_usesFrameStrip
                ? const Duration(milliseconds: 1250)
                : _previewResolved == target
                ? const Duration(milliseconds: 1850)
                : const Duration(seconds: 9),
          );
        }
      });
    }

    if (debounce) {
      _seekCommitTimer = Timer(
        Duration(milliseconds: webOs == null ? 350 : 125),
        commit,
      );
    } else {
      commit();
    }
  }

  void _selectFit(BoxFit fit) {
    setState(() => _fit = fit);
    _showControls();
  }

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

  Future<void> _browse() async {
    final sourceId = ref.read(activeSourceProvider).value?.id;
    if (sourceId == null || _browserOpen || _leaving) return;
    final previous = _item;
    _browserOpen = true;
    try {
      final choice = await showPlayerBrowsePanel(
        context,
        _queue,
        _index,
        sourceId,
        _panelMemory,
        decodedHeight: _controller?.value.size.height.round(),
      );
      if (!mounted ||
          _leaving ||
          choice == null ||
          !identical(previous, _item) ||
          _background ||
          ref.read(activeSourceProvider).value?.id != sourceId) {
        return;
      }
      final args = choice.items[choice.initialIndex].live
          ? choice
          : await preferLocalDownloads(
              ref.read(downloadManagerProvider.notifier),
              sourceId,
              choice,
            );
      if (!mounted ||
          _leaving ||
          !identical(previous, _item) ||
          _background ||
          ref.read(activeSourceProvider).value?.id != sourceId) {
        return;
      }
      _queue = args;
      _goTo(args.initialIndex);
    } finally {
      _browserOpen = false;
      if (mounted) _showControls();
    }
  }

  Future<void> _details() async {
    final id = _item.identity;
    if (id == null || _detailsOpen) return;
    final sourceId = ref.read(activeSourceProvider).value?.id;
    _detailsOpen = true;
    _resumeAfterDetails = _wantPlay && _error == null;
    _reportProgress();
    _pausePlayback();
    try {
      final route = id.itemType == 'SERIES' ? 'series' : 'movie';
      final result = await context.push<PlayerArgs>(
        '/$route/${id.itemId}',
        extra: playerDetailsOrigin,
      );
      if (!mounted || _leaving) return;
      _detailsOpen = false;
      if (_background ||
          ref.read(activeSourceProvider).value?.id != sourceId ||
          ref.read(castTargetProvider) != null) {
        return;
      }
      if (result != null) {
        _queue = result;
        _goTo(result.initialIndex);
      } else if (_resumeAfterDetails) {
        remoteResume();
      }
    } finally {
      _detailsOpen = false;
      _resumeAfterDetails = false;
      if (mounted) _showControls();
    }
  }

  void _pop() {
    if (_leaving) return;
    _leaving = true;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      Navigator.of(context).popUntil((r) => r == route || r.isFirst);
    }
    _handoff.end(_recovery);
    _session?.close();
    Navigator.of(context).pop(
      widget.args.returnChannelId
          ? int.tryParse(_item.identity?.itemId ?? '')
          : _index,
    );
  }

  // -- RemotePlayerHandle: transport driven from another device's remote. --

  @override
  RemotePlayerSnapshot remoteSnapshot() {
    final item = _playingQueue.items[_playingIndex];
    final value = _controller?.value;
    final state = _error != null
        ? 'idle'
        : !_wantPlay
        ? 'paused'
        : value == null || !value.isInitialized
        ? (value != null && _recovery.hasPlayed ? 'playing' : 'loading')
        : value.isPlaying
        ? 'playing'
        : 'paused';
    return RemotePlayerSnapshot(
      state: state,
      identity: item.identity,
      title: item.title,
      subtitle: item.subtitle,
      positionSec: item.live
          ? 0
          : (_lastPosition?.inSeconds ?? value?.position.inSeconds ?? 0),
      durationSec: item.live ? 0 : _lastDuration.inSeconds,
      hasPrev: _playlist && _hasPrev,
      hasNext: (_playlist && _hasNext) || _nextEpisode != null,
    );
  }

  @override
  void remotePause() {
    _cancelCountdown();
    _resumeAfterDetails = false;
    if (_wantPlay && _error == null) _pausePlayback();
  }

  @override
  void remoteResume() {
    if (_leaving ||
        _detailsOpen ||
        _background ||
        _wantPlay ||
        _error != null) {
      return;
    }
    if (_episodeFinished) {
      _goTo(_index, replay: true);
      return;
    }
    setState(() => _wantPlay = true);
    _setWakelock(true);
    _beginRecovery();
    final controller = _controller;
    if (_session?.current == true &&
        controller != null &&
        controller.value.isInitialized &&
        !controller.value.hasError) {
      final recovery = _recovery;
      unawaited(
        controller.play().then(
          (_) => recovery.playing(controller.value),
          onError: (Object e) => recovery.failure(e),
        ),
      );
    } else {
      unawaited(_openDecoder());
    }
  }

  @override
  void remoteSeek(Duration position) {
    _seekTo(position);
  }

  @override
  void remoteNext() {
    unawaited(_jumpEpisode(previous: false));
  }

  @override
  void remotePrev() {
    unawaited(_jumpEpisode(previous: true));
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
        : (_lastPosition?.inSeconds ??
              _controller?.value.position.inSeconds ??
              0);
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
    _handoff.end(_recovery);
    _session?.close();
    context.pushReplacement('/remote', extra: RemoteControlArgs(device));
  }

  void _handleBack() {
    if (_webOsVideo != null && _previewTarget != null) {
      _dismissVideoPreview();
      return;
    }
    if (_endActionFocus.context != null && _endCardVisible) {
      if (!_countdownCancelled &&
          _endViewer != null &&
          _nextEpisode != null &&
          ref.read(autoplayPreferenceProvider(_endViewer!)).value == true) {
        _cancelCountdown();
      } else {
        setState(() {
          _endDismissed = true;
          _endCardVisible = false;
        });
      }
      return;
    }
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
          LogicalKeyboardKey.browserBack,
          LogicalKeyboardKey.select,
          LogicalKeyboardKey.enter,
          LogicalKeyboardKey.space,
          LogicalKeyboardKey.mediaPlayPause,
          LogicalKeyboardKey.keyF,
        ].contains(event.logicalKey)) {
      return KeyEventResult.handled;
    }
    if (_endActionFocus.context != null && _endCardVisible) {
      if (_endScope.hasFocus &&
          {
            LogicalKeyboardKey.arrowUp,
            LogicalKeyboardKey.arrowDown,
            LogicalKeyboardKey.arrowLeft,
            LogicalKeyboardKey.arrowRight,
            LogicalKeyboardKey.space,
          }.contains(event.logicalKey)) {
        return KeyEventResult.ignored;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (_rootFocusNode.hasPrimaryFocus) {
          _endActionFocus.requestFocus();
          return KeyEventResult.handled;
        }
      }
      if ((event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select) &&
          !_rootFocusNode.hasPrimaryFocus) {
        return KeyEventResult.ignored;
      }
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape ||
          LogicalKeyboardKey.goBack ||
          LogicalKeyboardKey.browserBack:
        _handleBack();
      case LogicalKeyboardKey.keyF when isDesktopPlatform:
        _toggleFullscreen();
      case LogicalKeyboardKey.space || LogicalKeyboardKey.mediaPlayPause:
        _togglePlay();
      case LogicalKeyboardKey.mediaPlay:
        remoteResume();
        _showControls();
      case LogicalKeyboardKey.mediaPause:
        remotePause();
        _showControls();
      case LogicalKeyboardKey.select || LogicalKeyboardKey.enter:
        // Let a focused control or error button take Enter/Select.
        if (_error != null ||
            (_controlsVisible && FocusManager.instance.primaryFocus != node)) {
          return KeyEventResult.ignored;
        }
        _togglePlay();
      case LogicalKeyboardKey.mediaRewind ||
          LogicalKeyboardKey.mediaFastForward:
        _dpadSeek(
          Duration(
            seconds: event.logicalKey == LogicalKeyboardKey.mediaFastForward
                ? 10
                : -10,
          ),
        );
        if (_isTv &&
            !_item.live &&
            _error == null &&
            _rootFocusNode.hasPrimaryFocus &&
            _timelineFocus.context != null) {
          _overlayScope.descendantsAreFocusable = true;
          _timelineReturnFocus = null;
          _timelineFocus.requestFocus();
        }
      case LogicalKeyboardKey.arrowLeft || LogicalKeyboardKey.arrowRight:
        if (_error != null) return KeyEventResult.ignored;
        final forward =
            (event.logicalKey == LogicalKeyboardKey.arrowRight) ==
            (Directionality.of(context) == TextDirection.ltr);
        final canSeek =
            !_item.live &&
            _controller?.value.isInitialized == true &&
            _controller!.value.duration > Duration.zero;
        if (_isTv && canSeek) {
          final next = _playFocusNode.hasPrimaryFocus
              ? (forward ? _forwardFocus : _rewindFocus)
              : (forward ? _rewindFocus : _forwardFocus).hasPrimaryFocus
              ? _playFocusNode
              : null;
          if (next != null && next.context != null && next.canRequestFocus) {
            next.requestFocus();
            _showControls();
            return KeyEventResult.handled;
          }
        }
        if (_rootFocusNode.hasPrimaryFocus && canSeek) {
          _dpadSeek(Duration(seconds: forward ? 10 : -10));
          if (_isTv) {
            _overlayScope.descendantsAreFocusable = true;
            _timelineReturnFocus = null;
            _timelineFocus.requestFocus();
          }
        } else {
          if (_rootFocusNode.hasPrimaryFocus) return _enterControls();
          _showControls();
          return KeyEventResult.ignored;
        }
      case LogicalKeyboardKey.mediaTrackPrevious ||
          LogicalKeyboardKey.channelDown:
        remotePrev();
      case LogicalKeyboardKey.mediaTrackNext || LogicalKeyboardKey.channelUp:
        remoteNext();
      case LogicalKeyboardKey.arrowDown || LogicalKeyboardKey.arrowUp:
        if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
            (_playFocusNode.hasPrimaryFocus ||
                _rewindFocus.hasPrimaryFocus ||
                _forwardFocus.hasPrimaryFocus) &&
            _timelineFocus.context != null &&
            _controller?.value.isInitialized == true &&
            _controller!.value.duration > Duration.zero &&
            _isTv) {
          _timelineReturnFocus = FocusManager.instance.primaryFocus;
          _timelineFocus.requestFocus();
          _showControls();
          return KeyEventResult.handled;
        }
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

  Widget _buildVideo(VideoPlayerController controller, double aspectRatio) {
    final ar = aspectRatio > 0 ? aspectRatio : 16 / 9;
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
    final catalogId = _item.identity?.itemType == 'SERIES'
        ? int.tryParse(_item.identity!.itemId)
        : null;
    final catalog = catalogId == null || (_hasPrev && _hasNext)
        ? null
        : ref.watch(playerSeriesProvider(catalogId)).value;
    final previous =
        _hasPrev || _adjacentCatalogEpisode(catalog, previous: true) != null;
    final next =
        _hasNext || _adjacentCatalogEpisode(catalog, previous: false) != null;
    final controller = _controller;
    final form = formFactorOf(context, ref);
    final phone =
        isHandheldPlatform &&
        !form.isTv &&
        MediaQuery.sizeOf(context).shortestSide < 600;
    final autoplay =
        _endedController != null &&
        _endViewer != null &&
        ref.watch(autoplayPreferenceProvider(_endViewer!)).value == true &&
        !_countdownCancelled;
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
              onTap: () {
                if (_controlsVisible) {
                  _dismissVideoPreview();
                  setState(() => _controlsVisible = false);
                  _rootFocusNode.requestFocus();
                } else {
                  _showControls();
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (controller != null)
                    ValueListenableBuilder(
                      key: ObjectKey(controller),
                      valueListenable: controller,
                      builder: (context, value, _) {
                        if (!value.isInitialized) {
                          // Keep the existing texture mounted during retry backoff.
                          if (value.hasError && _decoderAspect != null) {
                            return _buildVideo(controller, _decoderAspect!);
                          }
                          return _recovery.hasPlayed || !_wantPlay
                              ? const SizedBox.expand()
                              : const _StatusIndicator(label: 'Loading…');
                        }
                        return _buildVideo(controller, value.aspectRatio);
                      },
                    )
                  else if (_error == null && _wantPlay && !_recovery.hasPlayed)
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
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
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
                                if (_item.live && _item.identity != null)
                                  OutlinedButton.icon(
                                    onPressed: _browse,
                                    icon: const Icon(Icons.tune_rounded),
                                    label: const Text('Try another version'),
                                  ),
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
                  IgnorePointer(
                    ignoring: !_controlsVisible,
                    child: AnimatedOpacity(
                      opacity: _controlsVisible ? 1 : 0,
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 200),
                      child: FocusScope(
                        node: _overlayScope,
                        descendantsAreFocusable: _controlsVisible,
                        descendantsAreTraversable: _controlsVisible,
                        child: _ControlsOverlay(
                          phone: phone,
                          onRotate: phone ? _rotatePlayer : null,
                          onFollowRotation: phone && _lockedOrientation != null
                              ? _followDeviceRotation
                              : null,
                          controller: controller,
                          volume: ref.watch(playerVolumeProvider),
                          onVolumeChanged: (volume) {
                            ref.read(playerVolumeProvider.notifier).set(volume);
                            unawaited(_controller?.setVolume(volume));
                            _showControls();
                          },
                          playFocusNode: _playFocusNode,
                          timelineFocus: _timelineFocus,
                          rewindFocus: _rewindFocus,
                          forwardFocus: _forwardFocus,
                          item: _item,
                          onBrowse:
                              _hasCatalogId &&
                                  (_item.live ||
                                      _item.identity?.itemType == 'SERIES')
                              ? _browse
                              : null,
                          onDetails:
                              _hasCatalogId &&
                                  {
                                    'MOVIE',
                                    'SERIES',
                                  }.contains(_item.identity?.itemType)
                              ? _details
                              : null,
                          onRestart:
                              controller?.value.isInitialized == true &&
                                  !_item.live
                              ? () {
                                  remoteSeek(Duration.zero);
                                  _showControls();
                                }
                              : null,
                          title: _item.title,
                          subtitle: _item.subtitle,
                          live: _item.live,
                          hasPrev: previous,
                          hasNext: next,
                          pictureFit: _fit,
                          subtitleTracks: _subtitleTracks,
                          activeSubtitle: _activeSubtitle,
                          audioTracks: _audioTracks,
                          activeAudio: _activeAudio,
                          onBack: _pop,
                          onCast: !kTvBuild && _item.identity != null
                              ? _cast
                              : null,
                          onTogglePlay: _togglePlay,
                          playingRequested: _wantPlay,
                          canTogglePlay: _error == null,
                          onSeekBy: _seekBy,
                          onSeekTo: (position) => _seekTo(
                            position,
                            debounce: _webOsVideo != null && _draggingTimeline,
                          ),
                          onDpadSeek: formFactorOf(context, ref).isTv
                              ? _dpadSeek
                              : null,
                          onTimelineDown: _leaveTimeline,
                          seekTarget: _seekTarget,
                          previewTarget: _previewTarget,
                          previewOrigin: _previewOrigin,
                          nativePreview: _usesFrameStrip,
                          seekWhileDragging: _webOsVideo != null,
                          onPreviewResolved: _previewFramesResolved,
                          onPrev: remotePrev,
                          onNext: remoteNext,
                          onSelectFit: _selectFit,
                          showFullscreen: isDesktopPlatform,
                          fullscreen: _fullscreen,
                          onToggleFullscreen: _toggleFullscreen,
                          onSelectSubtitle: _selectSubtitle,
                          onSelectAudio: _selectAudio,
                          onInteraction: _showControls,
                          onScrubbing: (value) => _draggingTimeline = value,
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 300),
                      child: _transitionItem != null && _error == null
                          ? EpisodeTransition(
                              series: _transitionItem!.title,
                              subtitle: _transitionItem!.subtitle,
                              imageUrl:
                                  _transitionItem!.episodeImage ??
                                  _transitionItem!.seriesCover,
                            )
                          : null,
                    ),
                  ),
                  if (_endCardVisible &&
                      (_episodeFinished || (autoplay && _nextEpisode != null)))
                    FocusScope(
                      node: _endScope,
                      child: EpisodeEndCard(
                        key: ValueKey(_episodeGeneration),
                        loading: _findingNext,
                        nextTitle: switch (_nextEpisode) {
                          (final queue, final i) =>
                            queue.items[i].subtitle.isEmpty
                                ? queue.items[i].title
                                : queue.items[i].subtitle,
                          null => null,
                        },
                        imageUrl: _nextEpisode == null
                            ? null
                            : (_nextEpisode!
                                      .$1
                                      .items[_nextEpisode!.$2]
                                      .episodeImage ??
                                  _nextEpisode!
                                      .$1
                                      .items[_nextEpisode!.$2]
                                      .seriesCover),
                        autoplay: autoplay,
                        secondsLeft: _endSeconds,
                        finished: _episodeFinished,
                        canAdvance: _canAdvanceEpisode,
                        cancelFocus: _endActionFocus,
                        onPlay: _playNextEpisode,
                        onCancel: _cancelCountdown,
                        onReplay: () => _goTo(_index, replay: true),
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

String _pictureFitLabel(BoxFit fit) => switch (fit) {
  BoxFit.cover => 'Fill',
  BoxFit.fill => 'Stretch',
  _ => 'Fit',
};

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({
    required this.phone,
    required this.onRotate,
    required this.onFollowRotation,
    required this.controller,
    required this.playFocusNode,
    required this.timelineFocus,
    required this.rewindFocus,
    required this.forwardFocus,
    required this.item,
    required this.onBrowse,
    required this.onDetails,
    required this.onRestart,
    required this.volume,
    required this.onVolumeChanged,
    required this.title,
    required this.subtitle,
    required this.live,
    required this.hasPrev,
    required this.hasNext,
    required this.pictureFit,
    required this.subtitleTracks,
    required this.activeSubtitle,
    required this.audioTracks,
    required this.activeAudio,
    required this.onBack,
    required this.onCast,
    required this.onTogglePlay,
    required this.playingRequested,
    required this.canTogglePlay,
    required this.onSeekBy,
    required this.onSeekTo,
    required this.onDpadSeek,
    required this.onTimelineDown,
    required this.seekTarget,
    required this.previewTarget,
    required this.previewOrigin,
    required this.nativePreview,
    required this.seekWhileDragging,
    required this.onPreviewResolved,
    required this.onPrev,
    required this.onNext,
    required this.onSelectFit,
    required this.showFullscreen,
    required this.fullscreen,
    required this.onToggleFullscreen,
    required this.onSelectSubtitle,
    required this.onSelectAudio,
    required this.onInteraction,
    required this.onScrubbing,
  });

  final bool phone;
  final VoidCallback? onRotate, onFollowRotation;
  final VideoPlayerController? controller;
  final FocusNode playFocusNode;
  final FocusNode timelineFocus;
  final FocusNode rewindFocus, forwardFocus;
  final PlayerItem item;
  final VoidCallback? onBrowse, onDetails, onRestart;
  final double volume;
  final ValueChanged<double> onVolumeChanged;
  final String title;
  final String subtitle;
  final bool live;
  final bool hasPrev;
  final bool hasNext;
  final BoxFit pictureFit;
  final List<(int, String)> subtitleTracks;
  final int? activeSubtitle;
  final List<(int, String)> audioTracks;
  final int? activeAudio;
  final VoidCallback onBack;
  final VoidCallback? onCast;
  final VoidCallback onTogglePlay;
  final bool playingRequested;
  final bool canTogglePlay;
  final void Function(Duration) onSeekBy;
  final ValueChanged<Duration> onSeekTo;
  final ValueChanged<Duration>? onDpadSeek;
  final VoidCallback onTimelineDown;
  final Duration? seekTarget;
  final Duration? previewTarget, previewOrigin;
  final bool nativePreview;
  final bool seekWhileDragging;
  final ValueChanged<Duration> onPreviewResolved;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<BoxFit> onSelectFit;

  /// Desktop-only OS-window fullscreen toggle.
  final bool showFullscreen;
  final bool fullscreen;
  final VoidCallback onToggleFullscreen;
  final ValueChanged<int?> onSelectSubtitle;
  final ValueChanged<int> onSelectAudio;
  final VoidCallback onInteraction;
  final ValueChanged<bool> onScrubbing;

  Future<void> _languages(BuildContext context) async {
    onInteraction();
    final selected = await showAppSheet<(bool, int?)>(
      context,
      title: 'Audio & subtitles',
      surfaceColor: const Color(0xF3191828),
      icon: Icons.subtitles_outlined,
      body: (sheet) {
        final audio = Column(
          children: [
            const AppSheetSectionLabel('Audio'),
            for (final (id, label) in audioTracks)
              AppSheetOption(
                title: label,
                selected: id == activeAudio,
                onPressed: () => Navigator.pop(sheet, (true, id)),
              ),
          ],
        );
        final subtitles = Column(
          children: [
            const AppSheetSectionLabel('Subtitles'),
            AppSheetOption(
              title: 'Off',
              selected: activeSubtitle == null,
              autofocus: activeSubtitle == null,
              onPressed: () => Navigator.pop(sheet, (false, null)),
            ),
            for (final (id, label) in subtitleTracks)
              AppSheetOption(
                title: label,
                autofocus: id == activeSubtitle,
                selected: id == activeSubtitle,
                onPressed: () => Navigator.pop(sheet, (false, id)),
              ),
          ],
        );
        return LayoutBuilder(
          builder: (context, bounds) {
            if (audioTracks.isEmpty) return subtitles;
            if (bounds.maxWidth < 520) {
              return Column(children: [audio, subtitles]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: audio),
                const SizedBox(width: 16),
                Expanded(child: subtitles),
              ],
            );
          },
        );
      },
    );
    if (!context.mounted || selected == null) return;
    onInteraction();
    if (selected.$1) {
      onSelectAudio(selected.$2!);
    } else {
      onSelectSubtitle(selected.$2);
    }
  }

  Future<BoxFit?> _pickFit(BuildContext context, BoxFit current) =>
      showAppSheet<BoxFit>(
        context,
        title: 'Picture fit',
        surfaceColor: const Color(0xF3191828),
        icon: Icons.aspect_ratio_rounded,
        body: (sheet) => Column(
          children: [
            for (final (fit, detail, icon) in [
              (
                BoxFit.contain,
                'Show the entire picture',
                Icons.fit_screen_rounded,
              ),
              (
                BoxFit.cover,
                'Fill the screen and crop the edges',
                Icons.crop_free_rounded,
              ),
              (
                BoxFit.fill,
                'Stretch the picture to fill the screen',
                Icons.aspect_ratio_rounded,
              ),
            ])
              AppSheetOption(
                title: _pictureFitLabel(fit),
                detail: detail,
                icon: icon,
                selected: current == fit,
                autofocus: current == fit,
                onPressed: () => Navigator.pop(sheet, fit),
              ),
          ],
        ),
      );
  Future<void> _more(BuildContext context) async {
    onInteraction();
    var selectedFit = pictureFit;
    final choice = await showAppSheet<VoidCallback>(
      context,
      title: 'Playback options',
      surfaceColor: const Color(0xF3191828),
      icon: Icons.tune_rounded,
      body: (sheet) => StatefulBuilder(
        builder: (context, setSheetState) => Column(
          children: [
            if (onRestart != null)
              AppSheetOption(
                autofocus: true,
                icon: Icons.replay_rounded,
                title: 'Restart from beginning',
                onPressed: () => Navigator.pop(sheet, onRestart),
              ),
            AppSheetOption(
              autofocus: onRestart == null,
              icon: Icons.aspect_ratio_rounded,
              title: 'Picture fit',
              detail: _pictureFitLabel(selectedFit),
              trailing: Icons.chevron_right_rounded,
              onPressed: () async {
                final fit = await _pickFit(sheet, selectedFit);
                if (fit == null || !sheet.mounted) return;
                onSelectFit(fit);
                setSheetState(() => selectedFit = fit);
              },
            ),
            if (onFollowRotation != null)
              AppSheetOption(
                icon: Icons.screen_rotation_rounded,
                title: 'Follow device rotation',
                onPressed: () => Navigator.pop(sheet, onFollowRotation),
              ),
            if (showFullscreen)
              AppSheetOption(
                icon: fullscreen
                    ? Icons.fullscreen_exit_rounded
                    : Icons.fullscreen_rounded,
                title: fullscreen ? 'Exit fullscreen' : 'Fullscreen',
                onPressed: () => Navigator.pop(sheet, onToggleFullscreen),
              ),
            if (onCast != null)
              AppSheetOption(
                icon: Icons.cast_rounded,
                title: 'Play on another device',
                onPressed: () => Navigator.pop(sheet, onCast),
              ),
          ],
        ),
      ),
    );
    if (context.mounted) {
      onInteraction();
      choice?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final insets = MediaQuery.paddingOf(context);
    final usableWidth = size.width - insets.horizontal;
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 23;
    final compact = phone || size.width < 700 || largeText;
    final landscape = size.width > size.height;
    final phoneToolbar = phone && landscape && usableWidth >= 510;
    final short = size.height - insets.vertical < 310;
    final iconLabels =
        (phoneToolbar && usableWidth < 730) || (phone && largeText);
    final margin = compact ? 10.0 : 24.0;
    const accent = Color(0xFFFFD7DF);
    final controlStyle =
        IconButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0x4628283A),
          minimumSize: const Size(44, 44),
        ).copyWith(
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? const BorderSide(color: Colors.white, width: 2)
                : BorderSide.none,
          ),
        );
    final series = item.identity?.itemType == 'SERIES';
    final canSeek =
        controller?.value.isInitialized == true &&
        controller!.value.duration > Duration.zero;
    Widget button(
      String text,
      IconData icon,
      VoidCallback action, {
      bool iconOnly = false,
    }) => iconLabels || iconOnly
        ? IconButton(tooltip: text, icon: Icon(icon), onPressed: action)
        : TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              minimumSize: const Size(44, 44),
              backgroundColor: const Color(0x402C283A),
              shape: const StadiumBorder(),
            ),
            onPressed: action,
            icon: Icon(icon, size: 20),
            label: Text(text),
          );
    final transport = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 5,
      children: [
        if (hasPrev)
          IconButton(
            tooltip: live
                ? 'Previous channel'
                : series
                ? 'Previous episode'
                : 'Previous',
            onPressed: onPrev,
            icon: const Icon(Icons.skip_previous_rounded),
          ),
        if (!live)
          IconButton(
            focusNode: rewindFocus,
            tooltip: 'Rewind 10 seconds',
            onPressed: canSeek
                ? () => onSeekBy(const Duration(seconds: -10))
                : null,
            icon: const Icon(Icons.replay_10_rounded),
          ),
        if (canTogglePlay)
          IconButton.filled(
            focusNode: playFocusNode,
            onPressed: onTogglePlay,
            tooltip: playingRequested ? 'Pause' : 'Play',
            style:
                IconButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: const Color(0xFF2C172D),
                  minimumSize: Size(short ? 50 : 56, short ? 50 : 56),
                ).copyWith(
                  side: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.focused)
                        ? const BorderSide(color: AppColors.primary, width: 3)
                        : BorderSide.none,
                  ),
                ),
            icon: Icon(
              playingRequested ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 30,
            ),
          ),
        if (!live)
          IconButton(
            focusNode: forwardFocus,
            tooltip: 'Forward 30 seconds',
            onPressed: canSeek
                ? () => onSeekBy(const Duration(seconds: 30))
                : null,
            icon: const Icon(Icons.forward_30_rounded),
          ),
        if (live && hasNext)
          IconButton(
            tooltip: 'Next channel',
            onPressed: onNext,
            icon: const Icon(Icons.skip_next_rounded),
          ),
        if (!live && hasNext)
          button(
            series ? 'Next episode' : 'Next',
            Icons.skip_next_rounded,
            onNext,
            iconOnly: phoneToolbar,
          ),
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 5,
      children: [
        if (onBrowse != null)
          button(
            live ? 'Channels' : 'Episodes',
            live ? Icons.live_tv_rounded : Icons.video_library_outlined,
            onBrowse!,
          ),
        if (onDetails != null)
          button(
            series ? 'Series details' : 'Movie details',
            Icons.info_outline_rounded,
            onDetails!,
            iconOnly: phoneToolbar && onBrowse != null,
          ),
        if (isFvpPlatform)
          IconButton(
            tooltip: 'Audio & subtitles',
            onPressed: () => _languages(context),
            icon: const Icon(Icons.subtitles_outlined),
          ),
        if (!isWebOsPlatform)
          PlayerVolumeButton(
            volume: volume,
            onChanged: onVolumeChanged,
            onInteraction: onInteraction,
          ),
        IconButton(
          tooltip: 'More playback options',
          onPressed: () => _more(context),
          icon: const Icon(Icons.more_horiz_rounded),
        ),
      ],
    );
    final centerTransport =
        phone &&
        !landscape &&
        !short &&
        canTogglePlay &&
        controller?.value.isInitialized == true;
    final overlay = IconButtonTheme(
      data: IconButtonThemeData(style: controlStyle),
      child: Column(
        children: [
          Container(
            padding: EdgeInsetsDirectional.fromSTEB(
              margin,
              phone ? 5 : insets.top + 10,
              margin,
              phone ? 10 : 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xD9070810),
                  Color(0x78070810),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: onBack,
                  icon: const BackButtonIcon(),
                ),
                SizedBox(width: live && compact ? 6 : 14),
                Expanded(
                  child: live
                      ? PlayerChannelHeader(
                          key: ObjectKey(item),
                          item: item,
                          compact: compact,
                          short: short,
                          decodedHeight: controller?.value.isInitialized == true
                              ? controller!.value.size.height.round()
                              : null,
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: short ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: compact ? 19 : 26,
                                fontWeight: FontWeight.w800,
                                height: 1.12,
                              ),
                            ),
                            if (subtitle.isNotEmpty)
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            if (!playingRequested && !short)
                              PlayerSynopsis(item: item),
                          ],
                        ),
                ),
                if (onRotate != null) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Rotate player',
                    onPressed: onRotate,
                    icon: const Icon(Icons.screen_rotation_rounded, size: 21),
                  ),
                ],
              ],
            ),
          ),
          if (centerTransport)
            Expanded(
              child: Center(
                child: NavigationGlass(
                  radius: 32,
                  outlined: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: transport,
                    ),
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          Container(
            padding: EdgeInsetsDirectional.fromSTEB(
              margin,
              phone ? 5 : 20,
              margin,
              phone ? 8 : insets.bottom + 14,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x620A0914),
                  Color(0xCF090914),
                ],
                stops: [0, .38, 1],
              ),
            ),
            // Seek previews paint above the dock. Clip only the glass backdrop.
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: NavigationGlass(
                    radius: compact ? 21 : 26,
                    outlined: false,
                    child: const SizedBox.expand(),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    compact ? 8 : 18,
                    2,
                    compact ? 8 : 18,
                    4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!live && controller != null)
                        _ProgressBar(
                          key: ObjectKey(controller),
                          controller: controller!,
                          onDpadSeek: onDpadSeek,
                          onTimelineDown: onTimelineDown,
                          seekTarget: seekTarget,
                          previewTarget: previewTarget,
                          previewOrigin: previewOrigin,
                          nativePreview: nativePreview,
                          seekWhileDragging: seekWhileDragging,
                          onPreviewResolved: onPreviewResolved,
                          title: item.subtitle.isEmpty
                              ? item.title
                              : item.subtitle,
                          artwork: item.episodeImage ?? item.seriesCover,
                          playFocus: playFocusNode,
                          timelineFocus: timelineFocus,
                          onTogglePlay: onTogglePlay,
                          onSeekTo: onSeekTo,
                          onSeeked: onInteraction,
                          onScrubbing: onScrubbing,
                        ),
                      if (!phoneToolbar && (compact || size.width < 940)) ...[
                        if (!centerTransport)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: transport,
                          ),
                        Align(
                          alignment: phone
                              ? Alignment.center
                              : AlignmentDirectional.centerStart,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: actions,
                          ),
                        ),
                      ] else
                        Row(
                          children: [
                            transport,
                            const SizedBox(width: 9),
                            Expanded(
                              child: Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: actions,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return phone ? SafeArea(child: overlay) : overlay;
  }
}

class _ProgressBar extends ConsumerStatefulWidget {
  const _ProgressBar({
    super.key,
    required this.controller,
    required this.onSeeked,
    required this.onDpadSeek,
    required this.onTimelineDown,
    required this.seekTarget,
    required this.previewTarget,
    required this.previewOrigin,
    required this.nativePreview,
    required this.seekWhileDragging,
    required this.onPreviewResolved,
    required this.title,
    this.artwork,
    required this.playFocus,
    required this.timelineFocus,
    required this.onTogglePlay,
    required this.onSeekTo,
    required this.onScrubbing,
  });
  final VideoPlayerController controller;
  final VoidCallback onSeeked;
  final ValueChanged<Duration>? onDpadSeek;
  final VoidCallback onTimelineDown;
  final Duration? seekTarget, previewTarget, previewOrigin;
  final bool nativePreview;
  final bool seekWhileDragging;
  final ValueChanged<Duration> onPreviewResolved;
  final String title;
  final String? artwork;
  final FocusNode playFocus;
  final FocusNode timelineFocus;
  final VoidCallback onTogglePlay;
  final ValueChanged<Duration> onSeekTo;
  final ValueChanged<bool> onScrubbing;
  @override
  ConsumerState<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends ConsumerState<_ProgressBar> {
  double? target;
  SeekPreviewMedia? _media;
  SeekFrameReader? _frameReader;
  PlaybackSeekFrames? _playbackFrames;
  void _focusChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    if (widget.nativePreview) {
      _frameReader = ref.read(seekFrameReaderProvider)(widget.controller);
      _playbackFrames = ref.read(playbackSeekFramesProvider)(widget.controller);
    } else {
      _media = SeekPreviewMedia(widget.controller);
      if (widget.previewTarget != null) _media?.request();
    }
    widget.timelineFocus.addListener(_focusChanged);
    FocusManager.instance.addEarlyKeyEventHandler(_onTimelineKey);
  }

  @override
  void dispose() {
    FocusManager.instance.removeEarlyKeyEventHandler(_onTimelineKey);
    widget.timelineFocus.removeListener(_focusChanged);
    _media?.dispose();
    _frameReader?.dispose();
    super.dispose();
  }

  // Slider maps all four arrows to percentage jumps. Intercept only when the
  // TV timeline is focused so pointer dragging and desktop shortcuts still work.
  KeyEventResult _onTimelineKey(KeyEvent event) {
    final seek = widget.onDpadSeek;
    if (seek == null ||
        !widget.timelineFocus.hasPrimaryFocus ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.select ||
          LogicalKeyboardKey.enter ||
          LogicalKeyboardKey.numpadEnter:
        if (event is KeyDownEvent) {
          widget.playFocus.requestFocus();
          widget.onTogglePlay();
        }
      case LogicalKeyboardKey.arrowRight || LogicalKeyboardKey.arrowLeft:
        final rightMeansForward =
            Directionality.of(context) == TextDirection.ltr;
        final forward =
            (event.logicalKey == LogicalKeyboardKey.arrowRight) ==
            rightMeansForward;
        seek(Duration(seconds: forward ? 10 : -10));
      case LogicalKeyboardKey.arrowUp:
        if (!widget.timelineFocus.focusInDirection(TraversalDirection.up)) {
          widget.playFocus.requestFocus();
        }
        widget.onSeeked();
      case LogicalKeyboardKey.arrowDown:
        widget.onTimelineDown();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  void didUpdateWidget(_ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewTarget != widget.previewTarget &&
        widget.previewTarget != null) {
      _media?.request();
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: widget.controller,
    builder: (context, value, _) {
      final max = value.duration.inMilliseconds.toDouble();
      final position =
          (target ??
                  (widget.seekTarget ?? value.position).inMilliseconds
                      .toDouble())
              .clamp(0.0, max < 0 ? 0.0 : max)
              .toDouble();
      final elapsed = Duration(milliseconds: position.round());
      final buffered = value.buffered
          .where((range) => range.start <= elapsed && range.end >= elapsed)
          .map((range) => range.end.inMilliseconds.toDouble())
          .fold<double>(0, (end, next) => end > next ? end : next);
      final focused = widget.timelineFocus.hasFocus;
      final preview = target == null
          ? widget.previewTarget
          : Duration(milliseconds: target!.round());
      const timeStyle = TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontFeatures: [FontFeature.tabularFigures()],
      );
      return Row(
        children: [
          Text(
            playbackClock(elapsed),
            textDirection: TextDirection.ltr,
            style: timeStyle,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final previewWidth = (width * .48)
                    .clamp(116.0, 188.0)
                    .clamp(0.0, width)
                    .toDouble();
                final filmstripWidth = (width * .55)
                    .clamp(265.0, 464.0)
                    .clamp(0.0, width)
                    .toDouble();
                final fraction = max > 0
                    ? (preview ?? elapsed).inMilliseconds / max
                    : 0.0;
                final fromStart =
                    Directionality.of(context) == TextDirection.ltr
                    ? fraction
                    : 1 - fraction;
                final anchor = width * fromStart.clamp(0.0, 1.0);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: focused ? 8 : 5,
                        activeTrackColor: const Color(0xFFFF6C88),
                        secondaryActiveTrackColor: const Color(0x99F0CCD9),
                        inactiveTrackColor: focused
                            ? Colors.white54
                            : Colors.white30,
                        thumbColor: Colors.white,
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: focused ? 9 : 6,
                        ),
                      ),
                      child: Semantics(
                        label: 'Playback position',
                        child: Slider(
                          focusNode: widget.timelineFocus,
                          value: position,
                          max: max > 0 ? max : 1,
                          secondaryTrackValue: buffered.clamp(
                            0.0,
                            max > 0 ? max : 1.0,
                          ),
                          semanticFormatterCallback: (v) =>
                              playbackClock(Duration(milliseconds: v.round())),
                          onChangeStart: max > 0
                              ? (v) {
                                  _media?.request();
                                  setState(() => target = v);
                                  widget.onScrubbing(true);
                                }
                              : null,
                          onChanged: max > 0
                              ? (v) {
                                  setState(() => target = v);
                                  if (widget.seekWhileDragging) {
                                    widget.onSeekTo(
                                      Duration(milliseconds: v.round()),
                                    );
                                  }
                                  widget.onSeeked();
                                }
                              : null,
                          onChangeEnd: max > 0
                              ? (v) {
                                  widget.onScrubbing(false);
                                  widget.onSeekTo(
                                    Duration(milliseconds: v.round()),
                                  );
                                  setState(() => target = null);
                                }
                              : null,
                        ),
                      ),
                    ),
                    if (_media != null && preview != null && previewWidth >= 72)
                      Positioned(
                        width: previewWidth,
                        left: (anchor - previewWidth / 2).clamp(
                          0.0,
                          width - previewWidth,
                        ),
                        bottom: 40,
                        child: SeekPreviewCard(
                          media: _media!,
                          target: preview,
                          origin: target != null
                              ? value.position
                              : widget.previewOrigin ?? value.position,
                          title: widget.title,
                          artwork: widget.artwork,
                        ),
                      ),
                    if (_frameReader != null)
                      AnimatedPositioned(
                        duration:
                            preview == null ||
                                MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        width: filmstripWidth,
                        left: (anchor - filmstripWidth / 2).clamp(
                          0.0,
                          width - filmstripWidth,
                        ),
                        bottom: 44,
                        child: SeekFilmstrip(
                          target: preview,
                          reader: _frameReader!,
                          onResolved: widget.onPreviewResolved,
                          playbackFrames: _playbackFrames,
                          playbackTarget:
                              target == null && widget.seekTarget == null
                              ? widget.previewTarget
                              : null,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Semantics(
            label: 'Time remaining',
            child: Text(
              '−${playbackClock(value.duration - elapsed)}',
              textDirection: TextDirection.ltr,
              style: timeStyle.copyWith(color: Colors.white70),
            ),
          ),
        ],
      );
    },
  );
}
