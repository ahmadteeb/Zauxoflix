import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'seek_preview.dart';
import 'seek_frames.dart';

class SeekFilmstrip extends StatefulWidget {
  const SeekFilmstrip({
    super.key,
    required this.target,
    required this.reader,
    required this.onResolved,
    this.playbackTarget,
    this.playbackFrames,
  });

  final Duration? target;
  final SeekFrameReader reader;
  final ValueChanged<Duration> onResolved;
  final Duration? playbackTarget;
  final PlaybackSeekFrames? playbackFrames;

  @override
  State<SeekFilmstrip> createState() => _SeekFilmstripState();
}

class _SeekFilmstripState extends State<SeekFilmstrip> {
  final _cache = <Duration, List<DecodedSeekFrame?>>{};
  Timer? _start;
  Duration? _pending;
  Duration? _reading;
  Duration? _playbackPending;
  Duration? _capturing;
  Duration? _shown;
  Duration? _unavailable;
  double _direction = 1;

  @override
  void initState() {
    super.initState();
    _request();
    _requestPlayback();
  }

  @override
  void didUpdateWidget(SeekFilmstrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.target != oldWidget.target) _request();
    if (widget.target != oldWidget.target ||
        widget.playbackTarget != oldWidget.playbackTarget) {
      _requestPlayback();
    }
  }

  @override
  void dispose() {
    _start?.cancel();
    super.dispose();
  }

  void _notifyResolved(Duration target) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final position = widget.target;
      if (mounted && position == target) {
        widget.onResolved(target);
      }
    });
  }

  void _request() {
    final target = widget.target;
    _pending = null;
    if (target == null) {
      _start?.cancel();
      _start = null;
      return;
    }
    if (_reading == target) return;
    final saved = _cache[target];
    if (saved?[1] != null) {
      _remember(target, saved!);
      _select(target);
      _notifyResolved(target);
      return;
    }
    _unavailable = null;
    _pending = target;
    if (_reading == null) {
      _start ??= Timer(const Duration(milliseconds: 95), _readLatest);
    }
  }

  void _select(Duration target) {
    if (_shown != null && target != _shown) {
      _direction = target > _shown! ? 1 : -1;
    }
    _shown = target;
  }

  void _remember(Duration target, List<DecodedSeekFrame?> frames) {
    final previous = _cache.remove(target);
    _cache[target] = List.generate(3, (slot) {
      final expected = target + Duration(seconds: slot - 1);
      final next = frames[slot];
      final old = previous?[slot];
      if (next == null) return old;
      if (old == null) return next;
      return (next.time - expected).abs() < (old.time - expected).abs()
          ? next
          : old;
    });
    if (_cache.length > 12) {
      final oldest = _cache.keys.firstWhere((time) => time != _shown);
      _cache.remove(oldest);
    }
  }

  void _requestPlayback() {
    final target = widget.target;
    final available =
        target != null &&
        target == widget.playbackTarget &&
        widget.playbackFrames != null;
    _playbackPending = available && _cache[target]?[1] == null ? target : null;
    if (_capturing == null && _playbackPending != null) {
      unawaited(_captureLatest());
    }
  }

  Future<void> _captureLatest() async {
    final target = _playbackPending;
    final capture = widget.playbackFrames;
    if (target == null || capture == null) return;
    _playbackPending = null;
    _capturing = target;
    bool current() =>
        mounted && widget.target == target && widget.playbackTarget == target;
    try {
      await capture(target, current, (slot, frame) {
        if (!current()) return;
        final hadCenter = _cache[target]?[1] != null;
        setState(() {
          final partial = List<DecodedSeekFrame?>.filled(3, null);
          partial[slot] = frame;
          _remember(target, partial);
          if (_cache[target]?[1] != null) {
            _unavailable = null;
            _select(target);
            if (!hadCenter) _notifyResolved(target);
          }
        });
      });
    } on Exception {
      // The independent reader can still finish the request.
    }
    _capturing = null;
    if (!mounted) return;
    if (current() &&
        _cache[target]?[1] == null &&
        _reading != target &&
        _pending != target) {
      setState(() => _unavailable = target);
      _notifyResolved(target);
    }
    if (_playbackPending != null) unawaited(_captureLatest());
  }

  Future<void> _readLatest() async {
    _start = null;
    final target = _pending;
    if (target == null || !mounted) return;
    _pending = null;
    _reading = target;
    List<DecodedSeekFrame?> frames;
    try {
      frames = await widget.reader.read(
        target,
        onFrames: (frames) {
          if (!mounted || widget.target != target) return;
          final hadCenter = _cache[target]?[1] != null;
          setState(() {
            _remember(target, frames);
            _select(target);
            if (!hadCenter && _cache[target]?[1] != null) {
              _notifyResolved(target);
            }
          });
        },
      );
    } on Exception {
      frames = const [];
    }
    if (!mounted) return;
    _reading = null;
    if (frames.length == 3) _remember(target, frames);
    if (widget.target == target) {
      setState(() {
        if (_cache[target]?[1] != null) {
          _select(target);
          _notifyResolved(target);
        } else if (widget.playbackFrames == null ||
            (widget.playbackTarget == target &&
                _capturing != target &&
                _playbackPending != target)) {
          _unavailable = target;
          _notifyResolved(target);
        }
      });
    }
    if (_pending != null) unawaited(_readLatest());
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    if (target == null && _shown == null) return const SizedBox.shrink();
    final timestamp = target ?? _shown ?? _unavailable ?? Duration.zero;
    final unavailable = target != null && _unavailable == target;
    final loading =
        target != null && _cache[target]?[1] == null && !unavailable;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final speed = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 180);
    final clock = playbackClock(timestamp);
    return IgnorePointer(
      child: AnimatedSlide(
        offset: target == null ? const Offset(0, .10) : Offset.zero,
        duration: speed,
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: target == null ? 0 : 1,
          duration: speed,
          child: ExcludeSemantics(
            excluding: target == null,
            child: Semantics(
              label: unavailable
                  ? 'Frame preview unavailable'
                  : loading
                  ? 'Loading video frames at $clock'
                  : 'Video frames at $clock',
              child: LayoutBuilder(
                builder: (context, bounds) {
                  final width = bounds.maxWidth;
                  final frames = _cache[timestamp];
                  final rendered =
                      unavailable ||
                          frames == null ||
                          frames.every((frame) => frame == null)
                      ? null
                      : frames;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (rendered != null) ...[
                        AnimatedSwitcher(
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 80),
                          layoutBuilder: (current, _) =>
                              current ?? const SizedBox.shrink(),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeOutCubic,
                          transitionBuilder: (child, animation) {
                            final from = reduceMotion
                                ? 0.0
                                : (rtl ? -.028 : .028) * _direction;
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: Offset(from, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _Frames(
                            key: ValueKey(timestamp),
                            width: width,
                            frames: rendered,
                          ),
                        ),
                        const SizedBox(height: 7),
                      ],
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xF2141721),
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 14,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (loading) ...[
                                if (!reduceMotion)
                                  const SizedBox.square(
                                    dimension: 11,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: Colors.white70,
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.hourglass_empty_rounded,
                                    size: 13,
                                  ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                clock,
                                key: target != null
                                    ? const ValueKey('seek-preview-time')
                                    : null,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              if (unavailable) ...[
                                const SizedBox(width: 8),
                                const Text('Frame preview unavailable'),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Frames extends StatelessWidget {
  const _Frames({super.key, required this.width, required this.frames});

  final double width;
  final List<DecodedSeekFrame?>? frames;

  @override
  Widget build(BuildContext context) {
    const proportions = [.29, .38, .29];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var slot = 0; slot < proportions.length; slot++)
          _Frame(
            key: frames?[slot] == null ? null : ValueKey('seek-frame-$slot'),
            width: width * proportions[slot],
            frame: frames?[slot],
            selected: slot == 1,
            outer: slot != 1,
          ),
      ],
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({
    super.key,
    required this.width,
    required this.frame,
    required this.selected,
    required this.outer,
  });

  final double width;
  final DecodedSeekFrame? frame;
  final bool selected, outer;

  @override
  Widget build(BuildContext context) => frame == null
      ? SizedBox(width: width)
      : SizedBox(
          width: width,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xE910131C),
                borderRadius: BorderRadius.circular(selected ? 11 : 8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: selected ? .68 : .44),
                    blurRadius: selected ? 20 : 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(selected ? 11 : 8),
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(selected ? 11 : 8),
                    border: Border.all(
                      color: selected ? AppColors.primary : Colors.white24,
                      width: selected ? 2 : 1,
                    ),
                    color: outer ? Colors.black.withValues(alpha: .19) : null,
                  ),
                  child: Image.memory(
                    frame!.image,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            ),
          ),
        );
}
