import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'skeleton.dart';

/// Disk-cached network image with a loading placeholder and error fallback.
/// Pass [memCacheWidth] to downscale in the decoder — full-size posters blow
/// the in-memory image cache on low-RAM boxes.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.placeholder,
    this.memCacheWidth,
    this.errorWidget,
    this.placeholderIconSize = 28,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? placeholder;
  final int? memCacheWidth;
  final Widget? errorWidget;
  final double placeholderIconSize;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      memCacheWidth: memCacheWidth,
      fadeInDuration: const Duration(milliseconds: 180),
      fadeOutDuration: const Duration(milliseconds: 120),
      filterQuality: FilterQuality.low,
      placeholder: (_, _) =>
          placeholder ??
          SkeletonPulse(
            child: SkeletonBox(width: width, height: height, radius: 0),
          ),
      errorWidget: (_, _, _) =>
          errorWidget ??
          ColoredBox(
            color: AppColors.surfaceLight,
            child: Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: placeholderIconSize,
                color: AppColors.textSecondary.withValues(alpha: 0.35),
              ),
            ),
          ),
    );
  }
}
