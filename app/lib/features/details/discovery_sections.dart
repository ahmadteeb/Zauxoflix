import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/media_item.dart';
import '../../core/responsive/form_factor.dart';
import '../../core/theme/app_theme.dart';
import '../home/widgets/content_rail.dart';
import 'media_navigation.dart';

class RelatedRail extends ConsumerWidget {
  const RelatedRail({
    super.key,
    required this.items,
    this.title = 'More like this',
    this.inset = true,
  });
  final List<MediaItem> items;
  final String title;
  final bool inset;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ContentRail(
    title: title,
    items: items,
    formFactor: formFactorOf(context, ref),
    inset: inset,
    onSelect: (item) => openMediaItem(context, ref, item),
  );
}

/// Retain the episode subtree and restore the scroll offset for each tab.
class SeriesSections extends StatefulWidget {
  const SeriesSections({
    super.key,
    required this.episodes,
    required this.items,
  });
  final Widget episodes;
  final List<MediaItem> items;
  @override
  State<SeriesSections> createState() => _SeriesSectionsState();
}

class _SeriesSectionsState extends State<SeriesSections> {
  bool related = false;
  final offsets = <bool, double>{};
  @override
  void didUpdateWidget(SeriesSections oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.isEmpty) related = false;
  }

  void select(bool next) {
    if (next == related) return;
    final scroll = Scrollable.maybeOf(context)?.position;
    if (scroll != null) {
      offsets[related] = scroll.pixels;
      offsets.putIfAbsent(next, () => scroll.pixels);
    }
    setState(() => related = next);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && scroll != null && scroll.hasContentDimensions) {
        scroll.jumpTo(
          (offsets[next] ?? 0).clamp(
            scroll.minScrollExtent,
            scroll.maxScrollExtent,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return widget.episodes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final tab in [false, true])
              ChoiceChip(
                label: Text(tab ? 'More like this' : 'Episodes'),
                selected: tab == related,
                showCheckmark: false,
                selectedColor: AppColors.surfaceLight,
                labelStyle: const TextStyle(color: AppColors.textPrimary),
                onSelected: (_) => select(tab),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Offstage(
          offstage: related,
          child: ExcludeFocus(excluding: related, child: widget.episodes),
        ),
        if (related) RelatedRail(items: widget.items, inset: false, title: ''),
      ],
    );
  }
}
