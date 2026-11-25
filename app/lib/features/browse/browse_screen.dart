import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/media_item.dart';
import '../../core/responsive/form_factor.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/catalog_search.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../details/media_navigation.dart';
import '../home/widgets/poster_card.dart';
import '../shell/top_nav_bar.dart';
import 'browse_controls.dart';

/// Shared category-filtered grid for Movies / Series. Each tab is a thin
/// wrapper choosing the [CatalogKind] and how rows map to [MediaItem]s.
class BrowseScreen extends ConsumerWidget {
  const BrowseScreen.movies({super.key})
    : kind = CatalogKind.vod,
      emptyMessage = 'No movies yet';

  const BrowseScreen.series({super.key})
    : kind = CatalogKind.series,
      emptyMessage = 'No series yet';

  final CatalogKind kind;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(activeSourceProvider).value;
    if (source == null) return const SizedBox.shrink();
    final db = ref.watch(databaseProvider);
    return _BrowseCatalog(
      key: ValueKey((db, source.id, kind)),
      sourceId: source.id,
      db: db,
      kind: kind,
      emptyMessage: emptyMessage,
      form: formFactorOf(context, ref),
    );
  }
}

class _BrowseCatalog extends StatefulWidget {
  const _BrowseCatalog({
    super.key,
    required this.sourceId,
    required this.db,
    required this.kind,
    required this.emptyMessage,
    required this.form,
  });

  final int sourceId;
  final AppDatabase db;
  final CatalogKind kind;
  final String emptyMessage;
  final FormFactor form;

  @override
  State<_BrowseCatalog> createState() => _BrowseCatalogState();
}

class _BrowseCatalogState extends State<_BrowseCatalog> {
  static const _pageSize = 60;

  String? _categoryId;
  CatalogSort _sort = CatalogSort.recentlyAdded;
  bool _filtersExpanded = false;
  final _filterFocus = FocusNode(debugLabel: 'Browse filters');
  final _search = TextEditingController();
  String _query = '';
  Timer? _searchTimer;
  int _limit = _pageSize;
  // True when the last emission filled the limit, so more rows may exist.
  bool _mayHaveMore = false;
  late final ScrollController _scroll = ScrollController()
    ..addListener(_maybeLoadMore);
  late final _categories = widget.db.watchCategories(
    widget.sourceId,
    widget.kind,
  );
  late Stream<List<MediaItem>> _items = _watchItems();

  @override
  void dispose() {
    _searchTimer?.cancel();
    _search.dispose();
    _filterFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Back to the first page and top of the grid after a filter/sort change.
  void _resetPaging({bool scrollToTop = true}) {
    _limit = _pageSize;
    _mayHaveMore = false;
    if (scrollToTop && _scroll.hasClients) _scroll.jumpTo(0);
    _items = _watchItems();
  }

  void _changeSearch(String text) {
    _searchTimer?.cancel();
    final query = catalogQuery(text);
    if (query == _query) return;
    void apply() {
      setState(() {
        _query = query;
        _resetPaging(scrollToTop: false);
      });
    }

    if (query.isEmpty) {
      apply();
    } else {
      _searchTimer = Timer(const Duration(milliseconds: 220), apply);
    }
  }

  void _resetFilters() {
    _searchTimer?.cancel();
    _search.clear();
    _filterFocus.requestFocus();
    setState(() {
      _query = '';
      _categoryId = null;
      _sort = CatalogSort.recentlyAdded;
      _resetPaging();
    });
  }

  void _maybeLoadMore() {
    if (!_mayHaveMore) return;
    if (_scroll.position.extentAfter > 800) return;
    setState(() {
      _limit += _pageSize;
      _mayHaveMore = false; // re-armed when the grown query fills up
      _items = _watchItems();
    });
  }

  Stream<List<MediaItem>> _watchItems() {
    final db = widget.db;
    final sourceId = widget.sourceId;
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
              search: _query,
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
              search: _query,
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
    final formFactor = widget.form;
    final gutter = formFactor.gutter;
    final topPadding = formFactor == FormFactor.mobile
        ? 8.0
        : kTopNavHeight + 12;
    final gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: switch (formFactor) {
        FormFactor.mobile => 130,
        FormFactor.tablet => 155,
        _ => 215,
      },
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 2 / 3,
    );

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 14),
            sliver: SliverToBoxAdapter(
              child: StreamBuilder<List<Category>>(
                stream: _categories,
                builder: (context, snapshot) => BrowseControls(
                  form: formFactor,
                  kind: widget.kind,
                  categories: snapshot.data ?? const [],
                  categoryId: _categoryId,
                  sort: _sort,
                  search: _search,
                  expanded: _filtersExpanded,
                  onToggle: () =>
                      setState(() => _filtersExpanded = !_filtersExpanded),
                  onCategory: (id) {
                    if (_categoryId == id) return;
                    setState(() {
                      _categoryId = id;
                      _resetPaging();
                    });
                  },
                  onSort: (sort) {
                    if (_sort == sort) return;
                    setState(() {
                      _sort = sort;
                      _resetPaging();
                    });
                  },
                  onSearch: _changeSearch,
                  onReset: _resetFilters,
                  filterFocus: _filterFocus,
                ),
              ),
            ),
          ),
          StreamBuilder<List<MediaItem>>(
            key: ValueKey((_categoryId, _sort, _query)),
            stream: _items,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                _mayHaveMore = false;
                return SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const EmptyState(
                        icon: Icons.error_outline_rounded,
                        title: 'Couldn’t load this catalog',
                      ),
                      TextButton(
                        onPressed: () => setState(_resetPaging),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              final items = snapshot.data;
              if (items == null) {
                return SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  sliver: SliverGrid.builder(
                    gridDelegate: gridDelegate,
                    itemCount: 12,
                    itemBuilder: (_, _) =>
                        const SkeletonPulse(child: SkeletonBox()),
                  ),
                );
              }
              _mayHaveMore =
                  snapshot.connectionState == ConnectionState.active &&
                  items.length >= _limit;
              if (items.isEmpty) {
                return SliverToBoxAdapter(
                  child: EmptyState(
                    icon: widget.kind == CatalogKind.vod
                        ? Icons.movie_outlined
                        : Icons.video_library_outlined,
                    title: _query.isEmpty
                        ? widget.emptyMessage
                        : 'No matching titles',
                    message: _query.isNotEmpty
                        ? 'Try a different title or change the category.'
                        : _categoryId == null
                        ? 'Sync your playlist to load the catalog.'
                        : 'This category is empty — try another one.',
                  ),
                );
              }
              return SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 32),
                sliver: SliverGrid.builder(
                  gridDelegate: gridDelegate,
                  itemCount: items.length,
                  itemBuilder: (context, i) =>
                      _GridTile(item: items[i], tvNavigation: formFactor.isTv),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GridTile extends ConsumerWidget {
  const _GridTile({required this.item, required this.tvNavigation});

  final bool tvNavigation;

  final MediaItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) => PosterCard(
        key: ValueKey((item.type, item.id)),
        item: item,
        width: constraints.maxWidth,
        tvNavigation: tvNavigation,
        onSelect: () => openMediaItem(context, ref, item),
      ),
    );
  }
}
