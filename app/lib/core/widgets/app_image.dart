import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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
    this.memCacheWidth,
    this.errorWidget,
    this.placeholderIconSize = 28,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
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
      memCacheWidth: memCacheWidth,
      fadeInDuration: const Duration(milliseconds: 180),
      fadeOutDuration: const Duration(milliseconds: 120),
      filterQuality: FilterQuality.low,
      placeholder: (_, _) => ColoredBox(
        color: AppColors.surfaceLight,
        child: Center(
          child: Icon(
            Icons.image_outlined,
            size: placeholderIconSize,
            color: AppColors.textSecondary.withValues(alpha: 0.35),
          ),
        ),
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
