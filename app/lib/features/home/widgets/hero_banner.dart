import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/input/input_modality.dart';
import '../../../core/models/media_item.dart';
import '../../../core/responsive/form_factor.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/tv/focusable.dart';

class HeroBanner extends StatelessWidget {
  const HeroBanner({
    super.key,
    required this.item,
    required this.formFactor,
    this.metaLine = '',
    this.onPlay,
    this.inMyList = false,
    this.onToggleMyList,
  });

  final MediaItem item;
  final FormFactor formFactor;

  /// "★ 7.2  ·  2019  ·  1h 52m  ·  Action" — below the title.
  final String metaLine;
  final VoidCallback? onPlay;
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
            : (size.height * 0.62).clamp(360.0, 760.0)) +
        (textScale - 1).clamp(0, 2) * 150;
    final gutter = formFactor.gutter;
    final titleSize = compact ? 32.0 : (size.width * 0.036).clamp(36.0, 64.0);

    // Background and text crossfade when the featured item rotates; the
    // buttons stay outside the switcher so their focus nodes survive.
    final heroKey = ValueKey(item.id ?? item.title);

    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 450),
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
                  image: item.imageUrl == null
                      ? null
                      : DecorationImage(
                          image: CachedNetworkImageProvider(item.imageUrl!),
                          fit: BoxFit.cover,
                          onError: (_, _) {},
                          colorFilter: ColorFilter.mode(
                            Colors.black.withValues(alpha: 0.45),
                            BlendMode.darken,
                          ),
                        ),
                ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: Container(
              padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 28),
              alignment: compact
                  ? Alignment.bottomCenter
                  : Alignment.bottomLeft,
              child: FocusTraversalGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: compact
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 300),
                      layoutBuilder: (current, previous) => Stack(
                        alignment: compact
                            ? Alignment.bottomCenter
                            : Alignment.bottomLeft,
                        children: [...previous, ?current],
                      ),
                      child: Column(
                        key: heroKey,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: compact
                            ? CrossAxisAlignment.center
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (metaLine.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              metaLine,
                              textAlign: compact
                                  ? TextAlign.center
                                  : TextAlign.start,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: compact ? 13 : 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: compact ? 520 : size.width * 0.42,
                            ),
                            child: Text(
                              item.subtitle,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              textAlign: compact
                                  ? TextAlign.center
                                  : TextAlign.start,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: compact ? 14 : 16,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        if (onPlay != null)
                          _HeroButton(
                            icon: Icons.play_arrow_rounded,
                            label: 'Play',
                            filled: true,
                            autofocus: InputModality.usesDpad,
                            onSelect: onPlay!,
                          ),
                        if (onToggleMyList != null) ...[
                          _HeroButton(
                            icon: inMyList ? Icons.check_rounded : Icons.add,
                            label: 'My List',
                            onSelect: onToggleMyList!,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
    this.filled = false,
    this.autofocus = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelect;
  final bool filled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.black : Colors.white;
    return Focusable(
      onSelect: onSelect,
      autofocus: autofocus,
      focusScale: 1.05,
      borderRadius: const BorderRadius.all(Radius.circular(6)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        color: filled ? Colors.white : Colors.white24,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pops when My List toggles between + and a check.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(icon, key: ValueKey(icon), color: fg, size: 24),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
