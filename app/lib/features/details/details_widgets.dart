import 'package:flutter/material.dart';

import '../../core/input/input_modality.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/skeleton.dart';

/// Shared Netflix-style details layout: backdrop, poster, metadata, Play.
/// Series screens pass [bottom] for the season/episode list.
class DetailsScaffold extends StatelessWidget {
  const DetailsScaffold({
    super.key,
    required this.title,
    required this.onPlay,
    this.posterUrl,
    this.backdropUrl,
    this.metaLine = '',
    this.plot,
    this.cast,
    this.director,
    this.loadingDetails = false,
    this.playLabel = 'Play',
    this.playProgress,
    this.favorite,
    this.onToggleFavorite,
    this.onCast,
    this.extraActions = const [],
    this.bottom,
  });

  final String title;
  final VoidCallback? onPlay;
  final String? posterUrl;
  final String? backdropUrl;
  final String metaLine;
  final String? plot;
  final String? cast;
  final String? director;
  final bool loadingDetails;
  final String playLabel;

  /// 0..1 fraction shown under the Play button when a resume point exists.
  final double? playProgress;

  /// Non-null shows the My List toggle.
  final bool? favorite;
  final VoidCallback? onToggleFavorite;

  /// Non-null shows the cast button (play on another device).
  final VoidCallback? onCast;

  /// Rendered after the built-in buttons (e.g. the download action).
  final List<Widget> extraActions;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact =
        size.width < 900 || MediaQuery.textScalerOf(context).scale(16) > 24;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (backdropUrl != null)
          AppImage(
            url: backdropUrl!,
            memCacheWidth: 1280,
            errorWidget: const SizedBox.shrink(),
          ),
        // Darken + fade so text stays readable over any artwork.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Color(0xE60B0B0F), AppColors.background],
              stops: [0, 0.55, 0.8],
            ),
          ),
        ),
        SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 20 : 48,
              8,
              compact ? 20 : 48,
              40,
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: BackButton(
                  style: IconButton.styleFrom(backgroundColor: Colors.black38),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!compact && posterUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AppImage(
                        url: posterUrl!,
                        width: 220,
                        height: 330,
                        memCacheWidth: 440,
                      ),
                    ),
                    const SizedBox(width: 32),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: compact ? 28 : 40,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (metaLine.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            metaLine,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (onPlay != null)
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FilledButton.icon(
                                    autofocus: InputModality.usesDpad,
                                    onPressed: onPlay,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 28,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 28,
                                    ),
                                    label: Text(
                                      playLabel,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (playProgress case final progress?) ...[
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: 160,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 3,
                                          backgroundColor:
                                              AppColors.surfaceLight,
                                          valueColor:
                                              const AlwaysStoppedAnimation(
                                                AppColors.primary,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            if (favorite case final fav?)
                              OutlinedButton.icon(
                                onPressed: onToggleFavorite,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white54),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                icon: Icon(
                                  fav ? Icons.check_rounded : Icons.add_rounded,
                                  size: 24,
                                ),
                                label: const Text(
                                  'My List',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (onCast != null)
                              Tooltip(
                                message: 'Play on a device',
                                child: OutlinedButton(
                                  onPressed: onCast,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Colors.white54,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.cast_rounded,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ...extraActions,
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (loadingDetails)
                          const DetailsTextSkeleton()
                        else ...[
                          if (plot != null)
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 720),
                              child: Text(
                                plot!,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          const SizedBox(height: 14),
                          if (cast != null) _CreditLine('Cast', cast!),
                          if (director != null)
                            _CreditLine('Director', director!),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (bottom != null) ...[const SizedBox(height: 28), bottom!],
            ],
          ),
        ),
      ],
    );
  }
}

class _CreditLine extends StatelessWidget {
  const _CreditLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
