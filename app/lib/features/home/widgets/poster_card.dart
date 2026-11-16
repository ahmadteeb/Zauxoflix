import 'package:flutter/material.dart';

import '../../../core/models/media_item.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/tv/focusable.dart';
import '../../../core/widgets/app_image.dart';

class PosterCard extends StatelessWidget {
  const PosterCard({
    super.key,
    required this.item,
    required this.width,
    this.wide = false,
    this.onSelect,
    this.onRemove,
  });

  final MediaItem item;
  final double width;
  final bool wide;
  final VoidCallback? onSelect;

  /// Long-press / right-click action, e.g. remove from Continue Watching.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final height = wide ? width * 9 / 16 : width * 3 / 2;

    final image = item.imageUrl == null
        ? _TextFallback(item: item)
        : AppImage(
            url: item.imageUrl!,
            width: width,
            height: height,
            memCacheWidth: (width * 2).round(),
            errorWidget: _TextFallback(item: item),
          );

    return Focusable(
      onSelect: onSelect,
      onLongPress: onRemove,
      child: Semantics(
        label: item.title,
        button: onSelect != null,
        image: item.imageUrl != null,
        child: SizedBox(
          width: width,
          height: height,
          child: item.progress == null && item.badge == null
              ? image
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    image,
                    if (item.badge case final badge?)
                      Positioned(
                        left: 6,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    if (item.progress case final progress?)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: Colors.black54,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _TextFallback extends StatelessWidget {
  const _TextFallback({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [item.color, Color.lerp(item.color, Colors.black, 0.55)!],
        ),
      ),
      padding: const EdgeInsets.all(10),
      alignment: Alignment.bottomLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              shadows: [Shadow(blurRadius: 6, color: Colors.black87)],
            ),
          ),
          if (item.subtitle.isNotEmpty)
            Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
