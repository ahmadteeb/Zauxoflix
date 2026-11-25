import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/input/input_modality.dart';
import '../../../core/models/media_item.dart';
import '../../../core/responsive/form_factor.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/title_artwork.dart';
import '../../../core/tv/focusable.dart';

class HeroBanner extends StatelessWidget {
  const HeroBanner({
    super.key,
    required this.item,
    required this.formFactor,
    this.metaLine = '',
    this.headlineLabel = '',
    this.navigation,
    this.onControlHover,
    this.loading = false,
    this.onPlay,
    this.playLabel = 'Play',
    this.onDetails,
    this.inMyList = false,
    this.onToggleMyList,
  });

  final MediaItem item;
  final bool loading;
  final FormFactor formFactor;

  /// "★ 7.2  ·  2019  ·  1h 52m  ·  Action" — below the title.
  final String metaLine;
  final String headlineLabel;
  final Widget? navigation;
  final ValueChanged<bool>? onControlHover;
  final VoidCallback? onPlay;
  final String playLabel;
  final VoidCallback? onDetails;
  final bool inMyList;
  final VoidCallback? onToggleMyList;

  @override
  Widget build(BuildContext context) {
    final compact = formFactor == FormFactor.mobile;
    final size = MediaQuery.sizeOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final height =
        (compact
            ? (size.height * 0.5).clamp(300.0, 480.0)
            : formFactor.isTv
            ? (size.height * .55).clamp(340.0, 680.0)
            : (size.height * 0.62).clamp(360.0, 760.0)) +
        (textScale - 1).clamp(0, 2) * 150;
    final gutter = formFactor.gutter;
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final wideControls =
        !compact && navigation != null && size.width >= 1080 * textScale;
    final titleSize = compact ? 38.0 : (size.width * .052).clamp(46.0, 86.0);

    if (loading) {
      return Semantics(
        label: 'Loading featured content',
        child: ExcludeSemantics(
          child: SkeletonPulse(
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const FractionallySizedBox(
                      widthFactor: .7,
                      child: SkeletonBox(height: 40),
                    ),
                    const SizedBox(height: 16),
                    const FractionallySizedBox(
                      widthFactor: .4,
                      child: SkeletonBox(height: 16),
                    ),
                    const SizedBox(height: 20),
                    const FractionallySizedBox(
                      widthFactor: .8,
                      child: SkeletonBox(height: 14),
                    ),
                    const SizedBox(height: 8),
                    const FractionallySizedBox(
                      widthFactor: .6,
                      child: SkeletonBox(height: 14),
                    ),
                    const SizedBox(height: 24),
                    const Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SkeletonBox(width: 120, height: 48),
                        SkeletonBox(width: 96, height: 48),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Background and text crossfade when the featured item rotates; the
    // buttons stay outside the switcher so their focus nodes survive.
    final heroKey = ValueKey((item.type, item.id ?? item.title));

    final fallback = item.type == null
        ? const SizedBox.shrink()
        : TitleArtwork(
            title: item.title,
            kind: ArtworkKind.forMedia(item.type),
            hasCaption: true,
          );
    final imageUrl = item.imageUrl?.trim();

    final dpad = formFactor.isTv || InputModality.usesDpad;
    List<Widget> actions([Axis? compactAxis]) => [
      if (onPlay != null)
        _HeroButton(
          icon: Icons.play_arrow_rounded,
          label: playLabel,
          filled: true,
          autofocus: dpad,
          onSelect: onPlay!,
          onHovered: onControlHover,
          compactAxis: compactAxis,
          ensureVisible: !formFactor.isTv,
        ),
      if (onDetails != null)
        _HeroButton(
          icon: Icons.info_outline_rounded,
          label: 'Details',
          filled: onPlay == null,
          autofocus: onPlay == null && dpad,
          onSelect: onDetails!,
          onHovered: onControlHover,
          compactAxis: compactAxis,
          ensureVisible: !formFactor.isTv,
        ),
      if (onToggleMyList != null)
        _HeroButton(
          icon: inMyList ? Icons.check_rounded : Icons.add,
          label: 'My List',
          onSelect: onToggleMyList!,
          onHovered: onControlHover,
          compactAxis: compactAxis,
          ensureVisible: !formFactor.isTv,
        ),
    ];
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: reduced
                  ? Duration.zero
                  : const Duration(milliseconds: 780),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.025, end: 1).animate(animation),
                  child: child,
                ),
              ),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              // The switcher's internal Stack gives loose constraints — a
              // childless DecoratedBox would lay out at zero size and paint
              // nothing, so it must be forced to fill the banner.
              layoutBuilder: (current, previous) => Stack(
                fit: StackFit.expand,
                children: [...previous, ?current],
              ),
              child: DecoratedBox(
                key: heroKey,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(item.color, Colors.black, 0.2)!,
                      Color.lerp(item.color, Colors.black, 0.6)!,
                      AppColors.background,
                    ],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl == null || imageUrl.isEmpty)
                      fallback
                    else
                      Image(
                        image: formFactor.isTv
                            ? ResizeImage(
                                CachedNetworkImageProvider(imageUrl),
                                width: 1600,
                                height: 1000,
                                policy: ResizeImagePolicy.fit,
                              )
                            : CachedNetworkImageProvider(imageUrl),
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.low,
                        color: Colors.black.withValues(alpha: .12),
                        colorBlendMode: BlendMode.darken,
                        frameBuilder: (_, child, frame, _) =>
                            frame == null ? fallback : child,
                        errorBuilder: (_, _, _) => fallback,
                      ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: compact
                              ? Alignment.bottomCenter
                              : Alignment.centerLeft,
                          end: compact
                              ? Alignment.topCenter
                              : Alignment.centerRight,
                          colors: const [
                            Color(0xF70B0B0F),
                            Color(0xAD0B0B0F),
                            Color(0x100B0B0F),
                          ],
                          stops: [0, compact ? .39 : .44, 1],
                        ),
                      ),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              Color(0xEE0B0B0F),
                            ],
                            stops: [0, .49, 1],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                gutter,
                formFactor.isTv ? 72 : 24,
                gutter,
                28,
              ),
              alignment: AlignmentDirectional.bottomStart,
              child: FocusTraversalGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: reduced
                          ? Duration.zero
                          : const Duration(milliseconds: 460),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position:
                              Tween(
                                begin: const Offset(0, .07),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: child,
                        ),
                      ),
                      layoutBuilder: (current, previous) => Stack(
                        alignment: AlignmentDirectional.bottomStart,
                        children: [...previous, ?current],
                      ),
                      child: Column(
                        key: heroKey,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (headlineLabel.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsetsDirectional.only(
                                start: 11,
                              ),
                              decoration: const BoxDecoration(
                                border: BorderDirectional(
                                  start: BorderSide(
                                    color: AppColors.primary,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Text(
                                headlineLabel,
                                textAlign: TextAlign.start,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: compact
                                  ? size.width
                                  : (size.width * .65).clamp(520.0, 1000.0),
                            ),
                            child: Text(
                              item.title,
                              textAlign: TextAlign.start,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.6,
                                height: 1.03,
                              ),
                            ),
                          ),
                          if (metaLine.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              metaLine,
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: compact ? 13 : 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (!compact || item.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: compact ? 520 : size.width * 0.42,
                              ),
                              child: Text(
                                item.subtitle,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  color: headlineLabel.isEmpty
                                      ? AppColors.textSecondary
                                      : const Color(0xfff0f0f3),
                                  fontSize: compact ? 14 : 16,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (compact)
                      LayoutBuilder(
                        builder: (context, box) {
                          // Allow larger type to keep whole words and their touch targets together.
                          final count = [
                            onPlay,
                            onDetails,
                            onToggleMyList,
                          ].nonNulls.length;
                          if (count == 0) return const SizedBox.shrink();
                          final slot = (box.maxWidth - 8 * (count - 1)) / count;
                          if (slot < 14 + 62 * textScale) {
                            return Column(
                              spacing: 8,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: actions(Axis.horizontal),
                            );
                          }
                          final vertical = slot < 28 + 72 * textScale;
                          return IntrinsicHeight(
                            child: Row(
                              spacing: 8,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final action in actions(
                                  vertical ? Axis.vertical : Axis.horizontal,
                                ))
                                  Expanded(child: action),
                              ],
                            ),
                          );
                        },
                      )
                    else
                      Wrap(spacing: 10, runSpacing: 8, children: actions()),
                    if (navigation != null && !wideControls) ...[
                      const SizedBox(height: 10),
                      navigation!,
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (wideControls)
            PositionedDirectional(
              end: gutter,
              bottom: 28,
              width: 340,
              child: FocusTraversalGroup(child: navigation!),
            ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.icon,
    required this.label,
    required this.onSelect,
    this.onHovered,
    this.compactAxis,
    required this.ensureVisible,
    this.filled = false,
    this.autofocus = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelect;
  final ValueChanged<bool>? onHovered;
  final Axis? compactAxis;
  final bool filled;
  final bool ensureVisible;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final compact = compactAxis != null;
    final fg = filled ? Colors.black : Colors.white;
    final symbol = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: Icon(
        icon,
        key: ValueKey(icon),
        color: fg,
        size: compact ? 20 : 24,
      ),
    );
    final caption = Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: fg,
        fontWeight: FontWeight.w700,
        fontSize: compact ? 14 : 15,
      ),
    );
    return Focusable(
      onSelect: onSelect,
      onHovered: onHovered,
      autofocus: autofocus,
      ensureVisible: ensureVisible,
      focusScale: compact ? 1.02 : 1.05,
      borderRadius: BorderRadius.circular(compact ? 14 : 26),
      child: Container(
        constraints: compact ? const BoxConstraints(minHeight: 42) : null,
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: filled ? Colors.white : const Color(0xBE222229),
          borderRadius: BorderRadius.circular(compact ? 11 : 23),
          border: Border.all(
            color: filled ? Colors.transparent : Colors.white38,
          ),
        ),
        child: compactAxis == Axis.vertical
            ? Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [symbol, const SizedBox(height: 2), caption],
              )
            : Row(
                mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  symbol,
                  SizedBox(width: compact ? 4 : 8),
                  if (compact) Flexible(child: caption) else caption,
                ],
              ),
      ),
    );
  }
}
