import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/media_artwork.dart';

class EpisodeEndCard extends StatefulWidget {
  const EpisodeEndCard({
    super.key,
    required this.nextTitle,
    this.imageUrl,
    required this.autoplay,
    required this.secondsLeft,
    required this.finished,
    required this.canAdvance,
    required this.onPlay,
    required this.onCancel,
    required this.onReplay,
    required this.cancelFocus,
    required this.loading,
  });
  final String? nextTitle, imageUrl;
  final bool autoplay, loading, finished;
  final int secondsLeft;
  final bool Function() canAdvance;
  final VoidCallback onPlay, onCancel, onReplay;
  final FocusNode cancelFocus;

  @override
  State<EpisodeEndCard> createState() => _EpisodeEndCardState();
}

class _EpisodeEndCardState extends State<EpisodeEndCard> {
  int fallback = 3;
  Timer? timer;
  bool get counting => widget.autoplay && widget.nextTitle != null;
  int get seconds => widget.finished ? fallback : widget.secondsLeft;

  @override
  void initState() {
    super.initState();
    if (widget.finished && counting) _afterEnd(false);
  }

  @override
  void didUpdateWidget(EpisodeEndCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!counting || !widget.finished) {
      timer?.cancel();
      timer = null;
    } else if (timer == null) {
      _afterEnd(
        !oldWidget.finished &&
            oldWidget.autoplay &&
            oldWidget.nextTitle != null,
      );
    }
  }

  void _afterEnd(bool showedCountdown) {
    // A seek or a decoder that jumps straight to EOF still gives the viewer a
    // full chance to cancel. Natural playback already displayed the countdown.
    fallback = showedCountdown ? 1 : 3;
    if (showedCountdown && widget.canAdvance()) {
      timer = Timer(Duration.zero, () {
        if (mounted && counting && widget.canAdvance()) {
          widget.onPlay();
        } else if (mounted && counting) {
          _afterEnd(false);
        }
      });
      return;
    }
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!widget.canAdvance()) return;
      if (fallback == 1) {
        t.cancel();
        widget.onPlay();
      } else {
        setState(() => fallback--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final size = MediaQuery.sizeOf(context);
    final parts = _episodeLabel(widget.nextTitle ?? '');
    final hasNext = widget.nextTitle != null;
    return SafeArea(
      child: Align(
        alignment: size.height < 440
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.bottomEnd,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            12,
            8,
            size.width >= 700 ? 26 : 12,
            size.height < 440
                ? 8
                : size.width >= 700
                ? 104
                : 152,
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: reduced
                ? Duration.zero
                : const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            builder: (_, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 14),
                child: child,
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Stack(
                        alignment: AlignmentDirectional.bottomStart,
                        children: [
                          Positioned.fill(
                            child: _Still(
                              url: widget.imageUrl,
                              title: parts.$2,
                            ),
                          ),
                          const Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x58000000),
                                    Color(0x80000000),
                                    Color(0xF416161D),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.skip_next_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        widget.loading
                                            ? 'Finding next episode…'
                                            : hasNext
                                            ? 'Up next'
                                            : 'Episode finished',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (counting)
                                      DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          child: Text(
                                            'Starting in $seconds s',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(
                                  height: hasNext && size.height >= 440
                                      ? 35
                                      : 6,
                                ),
                                if (parts.$1.isNotEmpty)
                                  Text(
                                    parts.$1,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                if (parts.$2.isNotEmpty)
                                  Text(
                                    parts.$2,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          height: 1.12,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (counting)
                        TweenAnimationBuilder<double>(
                          tween: Tween(end: seconds / 3),
                          duration: reduced
                              ? Duration.zero
                              : const Duration(milliseconds: 240),
                          builder: (_, v, _) => LinearProgressIndicator(
                            value: v,
                            minHeight: 2,
                            color: AppColors.primary,
                            backgroundColor: Colors.white12,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            if (hasNext)
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                ),
                                onPressed: widget.onPlay,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: Text(
                                  counting ? 'Play now' : 'Play next episode',
                                ),
                              ),
                            if (counting)
                              TextButton(
                                focusNode: widget.cancelFocus,
                                onPressed: widget.onCancel,
                                child: const Text('Cancel'),
                              )
                            else
                              TextButton.icon(
                                focusNode: widget.cancelFocus,
                                onPressed: widget.onReplay,
                                icon: const Icon(Icons.replay_rounded),
                                label: const Text('Replay'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

(String, String) _episodeLabel(String subtitle) {
  final separator = subtitle.indexOf(' — ');
  return separator < 0
      ? ('', subtitle)
      : (subtitle.substring(0, separator), subtitle.substring(separator + 3));
}

class _Still extends StatelessWidget {
  const _Still({required this.url, required this.title});
  final String title;
  final String? url;
  @override
  Widget build(BuildContext context) {
    return MediaArtwork(
      url: url,
      icon: Icons.video_library_outlined,
      radius: 0,
      title: title,
      kind: ArtworkKind.episode,
      hasCaption: true,
      cacheWidth: 768,
    );
  }
}

class EpisodeTransition extends StatelessWidget {
  const EpisodeTransition({
    super.key,
    required this.series,
    required this.subtitle,
    required this.imageUrl,
  });
  final String series, subtitle;
  final String? imageUrl;
  @override
  Widget build(BuildContext context) {
    final parts = _episodeLabel(subtitle);
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return Stack(
      fit: StackFit.expand,
      children: [
        _Still(url: imageUrl, title: parts.$2),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x33000000), Color(0x66000000), Color(0xEE09090D)],
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: AlignmentDirectional.bottomStart,
            child: Padding(
              padding: EdgeInsets.all(wide ? 48 : 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [series, if (parts.$1.isNotEmpty) parts.$1].join('  ·  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    parts.$2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: wide ? 38 : 25,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
