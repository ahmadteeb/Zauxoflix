import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/media_item.dart';
import '../../../core/widgets/media_artwork.dart';

/// The daily feed owns the order. This widget only controls presentation time.
class SpotlightRotation extends StatefulWidget {
  const SpotlightRotation({
    super.key,
    required this.slide,
    required this.index,
    required this.count,
    this.nextItem,
    required this.onMove,
    required this.builder,
  });
  final Object slide;
  final int index, count;
  final MediaItem? nextItem;
  final ValueChanged<int> onMove;
  final Widget Function(Widget? navigation, ValueChanged<bool> onControlHover)
  builder;
  @override
  State<SpotlightRotation> createState() => _SpotlightRotationState();
}

class _SpotlightRotationState extends State<SpotlightRotation>
    with WidgetsBindingObserver {
  static const _step = Duration(milliseconds: 150);
  static const _stepsPerSlide = 60;
  final _progress = ValueNotifier<double>(0);
  Timer? _timer;
  ScrollPosition? _scroll;
  ModalRoute<dynamic>? _outerRoute;
  int _steps = 0;
  bool _paused = false,
      _hover = false,
      _focus = false,
      _motion = true,
      _activeRoute = true,
      _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion =
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context);
    _activeRoute =
        // LG’s Flutter SDK exposes the inherited enabled flag through of().
        // ignore: deprecated_member_use
        TickerMode.of(context) && (ModalRoute.isCurrentOf(context) ?? true);
    final navigator = ModalRoute.of(context)?.navigator;
    _outerRoute = navigator == null ? null : ModalRoute.of(navigator.context);
    final scroll = Scrollable.maybeOf(context, axis: Axis.vertical)?.position;
    if (_scroll != scroll) {
      _scroll?.removeListener(_sync);
      _scroll = scroll;
      _scroll?.addListener(_sync);
    }
    _sync();
  }

  @override
  void didUpdateWidget(SpotlightRotation old) {
    super.didUpdateWidget(old);
    if (widget.slide != old.slide) {
      _reset();
    }
    _sync();
  }

  void _reset() {
    _steps = 0;
    _progress.value = 0;
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  void _sync() {
    final scroll = _scroll;
    final box = context.findRenderObject();
    // The spotlight is the first item in Home's vertical list.
    final visible =
        scroll == null ||
        !scroll.hasPixels ||
        box is! RenderBox ||
        !box.hasSize ||
        scroll.pixels < box.size.height * .7;
    final running =
        widget.count > 1 &&
        _motion &&
        _foreground &&
        _activeRoute &&
        !_paused &&
        !_hover &&
        !_focus &&
        visible;
    if (!running) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    if (_timer != null) return;
    var previousTick = 0;
    _timer = Timer.periodic(_step, (timer) {
      final elapsed = timer.tick - previousTick;
      previousTick = timer.tick;
      if (_outerRoute?.isCurrent == false) return;
      _steps += elapsed;
      if (_steps >= _stepsPerSlide) {
        _reset();
        widget.onMove(1);
      } else {
        _progress.value = _steps / _stepsPerSlide;
      }
    });
  }

  void _toggle() {
    setState(() => _paused = !_paused);
    if (!_paused) {
      _hover = false;
      _focus = false;
    }
    _sync();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll?.removeListener(_sync);
    WidgetsBinding.instance.removeObserver(this);
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controls = widget.count < 2
        ? null
        : ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Row(
              children: [
                Semantics(
                  label: 'Top pick ${widget.index + 1} of ${widget.count}',
                  child: Text(
                    '${(widget.index + 1).toString().padLeft(2, '0')} / ${widget.count.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ExcludeSemantics(
                    child: ValueListenableBuilder<double>(
                      valueListenable: _progress,
                      builder: (context, p, _) => Row(
                        spacing: 4,
                        children: [
                          for (int i = 0; i < widget.count; i++)
                            Expanded(
                              flex: i == widget.index ? 2 : 1,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  minHeight: 4,
                                  value: i == widget.index
                                      ? (_motion ? .10 + .90 * p : 1)
                                      : 0,
                                  backgroundColor: i < widget.index
                                      ? Colors.white70
                                      : Colors.white30,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Previous top pick',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => widget.onMove(-1),
                ),
                if (_motion)
                  IconButton(
                    tooltip: _paused ? 'Resume slideshow' : 'Pause slideshow',
                    icon: Icon(
                      _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      size: 20,
                    ),
                    onPressed: _toggle,
                  ),
                IconButton(
                  tooltip: 'Next top pick',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => widget.onMove(1),
                ),
              ],
            ),
          );
    final next = widget.nextItem;
    final navigation =
        controls != null &&
            next != null &&
            MediaQuery.sizeOf(context).width >=
                1080 * MediaQuery.textScalerOf(context).scale(1)
        ? SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: const Color(0xCE1A1A21),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                    side: const BorderSide(color: Colors.white24),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => widget.onMove(1),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          MediaArtwork(
                            url: next.imageUrl,
                            title: next.title,
                            kind: ArtworkKind.forMedia(next.type),
                            icon: next.type == MediaType.series
                                ? Icons.video_library_outlined
                                : Icons.movie_outlined,
                            width: 48,
                            height: 64,
                            cacheWidth: 128,
                            radius: 7,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Up next',
                                  style: TextStyle(
                                    color: Color(0xffcac8d0),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  next.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    height: 1.1,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                  ),
                ),
                controls,
              ],
            ),
          )
        : controls;
    void hover(bool over) {
      _hover = over;
      _sync();
    }

    return Focus(
      canRequestFocus: false,
      onFocusChange: (v) {
        _focus = v;
        _sync();
      },
      child: widget.builder(
        navigation == null
            ? null
            : MouseRegion(
                onEnter: (_) => hover(true),
                onExit: (_) => hover(false),
                child: navigation,
              ),
        hover,
      ),
    );
  }
}
