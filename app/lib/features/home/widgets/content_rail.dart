import 'package:flutter/material.dart';

import '../../../core/models/media_item.dart';
import '../../../core/responsive/form_factor.dart';
import '../../../core/widgets/skeleton.dart';
import 'poster_card.dart';

class ContentRail extends StatelessWidget {
  const ContentRail({
    super.key,
    required this.title,
    required this.items,
    required this.formFactor,
    this.wide = false,
    this.loading = false,
    this.onSelect,
    this.onRemove,
  });

  final String title;
  final List<MediaItem> items;
  final FormFactor formFactor;
  final bool wide;

  /// While true and [items] is empty, shows skeleton cards instead of
  /// collapsing — used during the first database read.
  final bool loading;

  final void Function(MediaItem item)? onSelect;

  /// Long-press / right-click per item, e.g. remove from Continue Watching.
  final void Function(MediaItem item)? onRemove;

  /// Cards visible per row, so widths scale with the window instead of
  /// being fixed pixel sizes.
  double get _cardsPerRow => switch (formFactor) {
    FormFactor.mobile => wide ? 1.8 : 3.2,
    FormFactor.tablet => wide ? 3.1 : 5.3,
    _ => wide ? 4.2 : 7.3,
  };

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && !loading) return const SizedBox.shrink();

    final gutter = formFactor.gutter;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = ((screenWidth - gutter * 2) / _cardsPerRow).clamp(
      90.0,
      420.0,
    );
    final cardHeight = wide ? cardWidth * 9 / 16 : cardWidth * 3 / 2;

    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 10),
            child: Text(
              title,
              style: TextStyle(
                fontSize: formFactor == FormFactor.mobile ? 17 : 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            // Extra room so the focus scale-up isn't clipped.
            height: cardHeight + 20,
            child: items.isEmpty
                ? SkeletonPulse(
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: gutter,
                        vertical: 8,
                      ),
                      itemCount: 10,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, _) => SkeletonBox(width: cardWidth),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                      horizontal: gutter,
                      vertical: 8,
                    ),
                    clipBehavior: Clip.none,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) => PosterCard(
                      item: items[i],
                      width: cardWidth,
                      wide: wide,
                      onSelect: () => onSelect?.call(items[i]),
                      onRemove: onRemove == null
                          ? null
                          : () => onRemove!(items[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
