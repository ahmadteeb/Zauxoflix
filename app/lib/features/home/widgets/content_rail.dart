import 'package:flutter/material.dart';

import '../../../core/models/media_item.dart';
import '../../../core/responsive/form_factor.dart';
import '../../../core/widgets/skeleton.dart';
import 'poster_card.dart';
import 'home_remote_navigation.dart';

class ContentRail extends StatefulWidget {
  const ContentRail({
    super.key,
    required this.title,
    required this.items,
    required this.formFactor,
    this.inset = true,
    this.wide = false,
    this.ranked = false,
    this.loading = false,
    this.onSelect,
    this.onRemove,
    this.onDetails,
  });

  final String title;
  final List<MediaItem> items;
  final FormFactor formFactor;
  final bool inset;
  final bool wide, ranked;

  /// While true and [items] is empty, shows skeleton cards instead of
  /// collapsing — used during the first database read.
  final bool loading;

  final void Function(MediaItem item)? onSelect;

  /// Long-press / right-click per item, e.g. remove from Continue Watching.
  final void Function(MediaItem item)? onRemove;

  final void Function(MediaItem item)? onDetails;

  @override
  State<ContentRail> createState() => _ContentRailState();
}

class _ContentRailState extends State<ContentRail> {
  final _scroll = ScrollController();
  final _edges = ValueNotifier((false, false));

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateEdges);
  }

  void _updateEdges() {
    if (!mounted ||
        !_scroll.hasClients ||
        !_scroll.position.hasContentDimensions) {
      return;
    }
    final p = _scroll.position;
    _edges.value = (p.extentBefore > 1, p.extentAfter > 1);
  }

  void _page(bool forward) {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    final offset = (p.pixels + (forward ? 1 : -1) * p.viewportDimension * .83)
        .clamp(p.minScrollExtent, p.maxScrollExtent)
        .toDouble();
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(offset);
    } else {
      _scroll.animateTo(
        offset,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _edges.dispose();
    super.dispose();
  }

  /// Cards visible per row, so widths scale with the window instead of
  /// being fixed pixel sizes.
  double get _cardsPerRow {
    if (widget.ranked) {
      return switch (widget.formFactor) {
        FormFactor.mobile => 1.65,
        FormFactor.tablet => 3.35,
        _ => 4.65,
      };
    }
    return switch (widget.formFactor) {
      FormFactor.mobile => widget.wide ? 1.55 : 3.2,
      FormFactor.tablet => widget.wide ? 3.1 : 5.3,
      _ => widget.wide ? 4.2 : 7.3,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && !widget.loading) return const SizedBox.shrink();

    final gutter = widget.inset ? widget.formFactor.gutter : 0.0;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = ((screenWidth - gutter * 2) / _cardsPerRow).clamp(
      90.0,
      420.0,
    );
    final cardHeight = widget.wide ? cardWidth * 9 / 16 : cardWidth * 3 / 2;

    final showArrows =
        widget.formFactor != FormFactor.mobile &&
        !widget.formFactor.isTv &&
        widget.items.isNotEmpty;
    final rail = FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title.isNotEmpty ||
              (widget.items.length > _cardsPerRow &&
                  (!widget.ranked || showArrows)))
            Padding(
              padding: EdgeInsets.fromLTRB(
                gutter,
                widget.ranked ? 0 : 20,
                gutter,
                widget.ranked ? 0 : 10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: widget.formFactor == FormFactor.mobile
                            ? 17
                            : 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (showArrows)
                    ValueListenableBuilder(
                      valueListenable: _edges,
                      builder: (_, edges, _) {
                        if (!edges.$1 && !edges.$2) {
                          return const SizedBox.shrink();
                        }
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final forward in [false, true])
                              IconButton(
                                tooltip:
                                    '${forward ? 'More' : 'Previous'} in ${widget.title.isEmpty ? (widget.ranked ? 'Top 10' : 'More like this') : widget.title}',
                                onPressed: (forward ? edges.$2 : edges.$1)
                                    ? () => _page(forward)
                                    : null,
                                icon: Icon(
                                  forward
                                      ? Icons.arrow_forward_rounded
                                      : Icons.arrow_back_rounded,
                                  size: 19,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          SizedBox(
            // Extra room so the focus scale-up isn't clipped.
            height: cardHeight + 20,
            child: widget.items.isEmpty
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
                : NotificationListener<ScrollMetricsNotification>(
                    onNotification: (_) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _updateEdges(),
                      );
                      return false;
                    },
                    child: ListView.separated(
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                        horizontal: gutter,
                        vertical: 8,
                      ),
                      clipBehavior: Clip.none,
                      itemCount: widget.items.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) => PosterCard(
                        key: ValueKey((
                          widget.items[i].type,
                          widget.items[i].id,
                          widget.items[i].title,
                        )),
                        item: widget.items[i],
                        rank: widget.ranked
                            ? (widget.items[i].chartRank ?? i + 1)
                            : null,
                        width: cardWidth,
                        wide: widget.wide,
                        tvNavigation: widget.formFactor.isTv,
                        onSelect: widget.onSelect == null
                            ? null
                            : () => widget.onSelect!(widget.items[i]),
                        onDetails:
                            widget.onDetails == null ||
                                widget.items[i].id == null
                            ? null
                            : () => widget.onDetails!(widget.items[i]),
                        onRemove: widget.onRemove == null
                            ? null
                            : () => widget.onRemove!(widget.items[i]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
    return widget.formFactor.isTv
        ? HomeFocusRow(
            key: PageStorageKey((widget.title, widget.key)),
            railGutter: gutter,
            child: rail,
          )
        : rail;
  }
}
