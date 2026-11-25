import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_image.dart';
import 'title_artwork.dart';

export 'title_artwork.dart';

/// Consistent frames for posters, episode stills and transparent channel logos.
class MediaArtwork extends StatelessWidget {
  const MediaArtwork({
    super.key,
    this.url,
    required this.icon,
    this.width,
    this.height,
    this.logo = false,
    this.radius = 8,
    required this.title,
    required this.kind,
    this.hasCaption = false,
    required this.cacheWidth,
    this.progress,
    this.fallbackArtwork,
  });

  final String? url;
  final IconData icon;
  final double? width, height, progress;
  final Widget? fallbackArtwork;
  final bool logo;
  final double radius;
  final String title;
  final ArtworkKind kind;
  final bool hasCaption;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    final cover = TitleArtwork(
      title: title,
      kind: kind,
      hasCaption: hasCaption,
      emptyIcon: icon,
    );
    final fallback = fallbackArtwork ?? cover;
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: AppColors.surfaceLight,
              child: url?.trim().isNotEmpty == true
                  ? Padding(
                      padding: EdgeInsets.all(logo ? 4 : 0),
                      child: AppImage(
                        url: url!.trim(),
                        fit: logo ? BoxFit.contain : BoxFit.cover,
                        memCacheWidth: cacheWidth,
                        placeholder: cover,
                        errorWidget: fallback,
                      ),
                    )
                  : fallback,
            ),
            if (progress != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: LinearProgressIndicator(
                  value: progress!.clamp(0, 1),
                  minHeight: 3,
                  semanticsLabel: 'Watch progress',
                  backgroundColor: Colors.black54,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
