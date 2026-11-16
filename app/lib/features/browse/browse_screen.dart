import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/media_item.dart';
import '../../core/responsive/form_factor.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../details/media_navigation.dart';
import '../home/widgets/poster_card.dart';
import '../shell/top_nav_bar.dart';
import 'category_dropdown.dart';
import 'sort_dropdown.dart';

/// Shared category-filtered grid for Movies / Series. Each tab is a thin
/// wrapper choosing the [CatalogKind] and how rows map to [MediaItem]s.
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen.movies({super.key})
    : kind = CatalogKind.vod,
      emptyMessage = 'No movies yet';

  const BrowseScreen.series({super.key})
    : kind = CatalogKind.series,
      emptyMessage = 'No series yet';

  final CatalogKind kind;
  final String emptyMessage;

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  static const _pageSize = 60;

  String? _categoryId;
  CatalogSort _sort = CatalogSort.recentlyAdded;
  int _limit = _pageSize;
  // True when the last emission filled the limit, so more rows may exist.
  bool _mayHaveMore = false;
  late final ScrollController _scroll = ScrollController()
    ..addListener(_maybeLoadMore);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Back to the first page and top of the grid after a filter/sort change.
  void _resetPaging() {
    _limit = _pageSize;
    _mayHaveMore = false;
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _maybeLoadMore() {
    if (!_mayHaveMore) return;
    if (_scroll.position.extentAfter > 800) return;
    setState(() {
      _limit += _pageSize;
      _mayHaveMore = false; // re-armed when the grown query fills up
    });
  }

  Stream<List<MediaItem>> _watchItems(AppDatabase db, int sourceId) {
    final limit = _limit;
    return switch (widget.kind) {
      // Live TV uses LiveTvScreen (list + mini player), not this grid.
      CatalogKind.live => const Stream.empty(),
      CatalogKind.vod =>
        db
            .watchMovies(
              sourceId,
              categoryId: _categoryId,
              sort: _sort,
              limit: limit,
            )
            .map(
              (rows) => [
                for (final m in rows)
                  MediaItem(
                    title: m.name,
                    imageUrl: m.icon,
                    type: MediaType.movie,
                    id: m.streamId,
                    containerExtension: m.containerExtension,
                  ),
              ],
            ),
      CatalogKind.series =>
        db
            .watchSeries(
              sourceId,
              categoryId: _categoryId,
              sort: _sort,
              limit: limit,
            )
            .map(
              (rows) => [
                for (final s in rows)
                  MediaItem(
                    title: s.name,
                    imageUrl: s.cover,
                    type: MediaType.series,
                    id: s.seriesId,
                  ),
              ],
            ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final formFactor = formFactorOf(context, ref);
    final source = ref.watch(activeSourceProvider).value;
    final db = ref.watch(databaseProvider);

    if (source == null) return const SizedBox.shrink();

    final gutter = formFactor.gutter;
    final topPadding = formFactor == FormFactor.mobile
        ? 12.0
        : kTopNavHeight + 12;

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow =
                  constraints.maxWidth < 500 ||
                  MediaQuery.textScalerOf(context).scale(14) > 20;
              final category = StreamBuilder(
                stream: db.watchCategories(source.id, widget.kind),
                builder: (context, snapshot) => CategoryDropdown(
                  categories: snapshot.data ?? const [],
                  selectedId: _categoryId,
                  onChanged: (id) => setState(() {
                    _categoryId = id;
                    _resetPaging();
                  }),
                  gutter: 0,
                ),
              );
              final sort = SortDropdown(
                selected: _sort,
                onChanged: (sort) => setState(() {
                  _sort = sort;
                  _resetPaging();
                }),
              );
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                child: narrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [category, const SizedBox(height: 8), sort],
                      )
                    : Row(
                        children: [
                          Expanded(child: category),
                          const SizedBox(width: 12),
                          sort,
                        ],
                      ),
              );
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder(
              stream: _watchItems(db, source.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return PosterGridSkeleton(gutter: gutter);
                }
                final items = snapshot.data ?? const <MediaItem>[];
                if (items.isEmpty) {
                  return EmptyState(
                    icon: widget.kind == CatalogKind.vod
                        ? Icons.movie_outlined
                        : Icons.video_library_outlined,
                    title: widget.emptyMessage,
                    message: _categoryId == null
                        ? 'Sync your playlist to load the catalog.'
                        : 'This category is empty — try another one.',
                  );
                }
                _mayHaveMore = items.length >= _limit;
                final maxExtent = switch (formFactor) {
                  FormFactor.mobile => 130.0,
                  FormFactor.tablet => 155.0,
                  _ => 215.0,
                };
                return FocusTraversalGroup(
                  child: GridView.builder(
                    controller: _scroll,
                    padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 32),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: maxExtent,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 2 / 3,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, i) => _GridTile(item: items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GridTile extends ConsumerWidget {
  const _GridTile({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) => PosterCard(
        item: item,
        width: constraints.maxWidth,
        onSelect: () => openMediaItem(context, ref, item),
      ),
    );
  }
}
