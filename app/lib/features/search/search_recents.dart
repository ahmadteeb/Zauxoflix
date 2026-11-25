import 'package:flutter/material.dart';

import '../../core/models/media_item.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/catalog_row_card.dart';
import '../shell/navigation_glass.dart';

class SearchRecents extends StatelessWidget {
  const SearchRecents({
    super.key,
    required this.queries,
    required this.opened,
    required this.gutter,
    required this.onSearch,
    required this.onOpen,
    required this.onClear,
  });

  final List<String> queries;
  final List<MediaItem> opened;
  final double gutter;
  final ValueChanged<String> onSearch;
  final ValueChanged<MediaItem> onOpen;
  final ValueChanged<bool> onClear;

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 32),
    children: [
      if (queries.isNotEmpty)
        _HistorySection(
          title: 'Recent searches',
          clearLabel: 'Clear recent searches',
          onClear: () => onClear(false),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final query in queries)
                Tooltip(
                  key: ValueKey(query),
                  message: query,
                  excludeFromSemantics: true,
                  child: TextButton.icon(
                    onPressed: () => onSearch(query),
                    icon: const Icon(Icons.history_rounded, size: 18),
                    label: Text(
                      query,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style:
                        TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          backgroundColor: AppColors.controlSurface,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ).copyWith(
                          side: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.focused)
                                ? const BorderSide(
                                    color: AppColors.focusRing,
                                    width: 2,
                                  )
                                : BorderSide.none,
                          ),
                        ),
                  ),
                ),
            ],
          ),
        ),
      if (queries.isNotEmpty && opened.isNotEmpty) const SizedBox(height: 16),
      if (opened.isNotEmpty)
        _HistorySection(
          title: 'Recently opened',
          clearLabel: 'Clear recently opened',
          onClear: () => onClear(true),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const gap = 8.0;
              final width = constraints.maxWidth;
              return Wrap(
                spacing: gap,
                children: [
                  for (final item in opened)
                    SizedBox(
                      key: ValueKey((item.type, item.id)),
                      width: width >= 650 ? (width - gap) / 2 : width,
                      child: CatalogRowCard(
                        title: item.title,
                        caption: item.kindLabel,
                        image: item.imageUrl,
                        icon: switch (item.type) {
                          MediaType.live => Icons.live_tv_rounded,
                          MediaType.series => Icons.video_library_rounded,
                          _ => Icons.movie_rounded,
                        },
                        logo: item.type == MediaType.live,
                        trailing: const Icon(Icons.chevron_right_rounded),
                        blended: true,
                        onSelect: () => onOpen(item),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
    ],
  );
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({
    required this.title,
    required this.clearLabel,
    required this.onClear,
    required this.child,
  });

  final String title, clearLabel;
  final VoidCallback onClear;
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.topStart,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1100),
      child: NavigationGlass(
        radius: 18,
        outlined: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onClear,
                    child: Semantics(
                      label: clearLabel,
                      excludeSemantics: true,
                      child: const Text('Clear'),
                    ),
                  ),
                ],
              ),
              child,
            ],
          ),
        ),
      ),
    ),
  );
}
