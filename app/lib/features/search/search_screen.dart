import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/input/input_modality.dart';
import '../../core/models/media_item.dart';
import '../../core/responsive/form_factor.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/dpad_text_field.dart';
import '../../data/db/app_database.dart';
import '../../data/catalog_search.dart';
import '../../data/live/live_directory.dart';
import '../../data/live/live_providers.dart';
import '../../data/providers.dart';
import '../details/media_navigation.dart';
import '../home/widgets/content_rail.dart';
import '../shell/top_nav_bar.dart';
import 'search_history.dart';
import 'search_recents.dart';

typedef _SearchResults = ({
  List<LiveChannel> channels,
  List<Movie> movies,
  List<SeriesItem> series,
});

final _catalogResults = Provider.autoDispose
    .family<Future<_SearchResults>, (int, String)>((ref, key) async {
      final db = ref.watch(databaseProvider);
      ref.watch(activeSourceProvider.select((s) => s.value?.lastSyncAt));
      final (channels, movies, series) = await (
        db.searchLiveChannels(key.$1, key.$2),
        db.searchMovies(key.$1, key.$2),
        db.searchSeries(key.$1, key.$2),
      ).wait;
      return (channels: channels, movies: movies, series: series);
    });

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    if (text.trim().isEmpty) {
      setState(() => _query = '');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = text.trim());
    });
  }

  void _submit(String text, {bool restoreText = false}) {
    _debounce?.cancel();
    final query = text.trim();
    if (restoreText) {
      FocusManager.instance.primaryFocus?.unfocus();
      _controller.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
    setState(() => _query = query);
    final scope = ref.read(searchHistoryScopeProvider);
    if (scope != null) {
      unawaited(
        ref.read(searchHistoryProvider(scope).notifier).record(query: query),
      );
    }
  }

  void _open(MediaItem item, {String? query}) {
    final scope = ref.read(searchHistoryScopeProvider);
    if (scope != null) {
      unawaited(
        ref
            .read(searchHistoryProvider(scope).notifier)
            .record(query: query, item: item),
      );
    }
    openMediaItem(context, ref, item);
  }

  Future<void> _clear(SearchHistoryScope scope, bool opened) async {
    try {
      await ref
          .read(searchHistoryProvider(scope).notifier)
          .clear(opened: opened);
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not clear search history. Try again.'),
          ),
        );
      }
    }
  }

  Widget _recents(double gutter) {
    final scope = ref.watch(searchHistoryScopeProvider);
    if (scope != null) {
      final queries =
          ref.watch(searchHistoryProvider(scope)).value?.queries ??
          const <String>[];
      final opened =
          ref.watch(recentlyOpenedSearchResultsProvider(scope)).value ??
          const <MediaItem>[];
      if (queries.isNotEmpty || opened.isNotEmpty) {
        return SearchRecents(
          key: ValueKey(scope),
          queries: queries,
          opened: opened,
          gutter: gutter,
          onSearch: (text) => _submit(text, restoreText: true),
          onOpen: _open,
          onClear: (opened) => unawaited(_clear(scope, opened)),
        );
      }
    }
    return const _CenteredHint(
      icon: Icons.search_rounded,
      text: 'Search channels, movies and series',
    );
  }

  @override
  Widget build(BuildContext context) {
    final formFactor = formFactorOf(context, ref);
    final compact = formFactor == FormFactor.mobile;
    final sourceId = ref.watch(activeSourceProvider).value?.id;
    final normalized = catalogQuery(_query);
    final key = (sourceId ?? 0, _query);
    final resultsFuture = sourceId == null || normalized.isEmpty
        ? null
        : ref.watch(_catalogResults(key));
    final directory = sourceId == null || normalized.isEmpty
        ? null
        : ref.watch(liveDirectoryProvider(sourceId)).value;
    final gutter = formFactor.gutter;
    final topPadding = compact ? 12.0 : kTopNavHeight + 12;

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: DpadTextField(
                autofocus: InputModality.usesDpad,
                builder: (context, fieldNode) => TextField(
                  controller: _controller,
                  focusNode: fieldNode,
                  onChanged: _onChanged,
                  onSubmitted: _submit,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search your library…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _controller.clear();
                              _onChanged('');
                            },
                          ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: resultsFuture == null
                ? _recents(gutter)
                : FutureBuilder(
                    key: ValueKey(key),
                    future: resultsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Could not search the catalog.',
                                  textAlign: TextAlign.center,
                                ),
                                TextButton(
                                  onPressed: () =>
                                      ref.invalidate(_catalogResults(key)),
                                  child: const Text('Try again'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final results = snapshot.data;
                      if (results == null) {
                        return ListView(
                          padding: const EdgeInsets.only(bottom: 32),
                          children: [
                            ContentRail(
                              title: 'Movies',
                              items: const [],
                              formFactor: formFactor,
                              loading: true,
                            ),
                            ContentRail(
                              title: 'Series',
                              items: const [],
                              formFactor: formFactor,
                              loading: true,
                            ),
                          ],
                        );
                      }
                      final groups = directory == null
                          ? const <LiveStation>[]
                          : directory.stations
                                .where(
                                  (station) => station.matches(
                                    normalized,
                                    int.tryParse(normalized),
                                  ),
                                )
                                .take(48)
                                .toList();
                      final channels = directory == null
                          ? results.channels
                          : [
                              for (final station in groups)
                                station.channel.copyWith(name: station.name),
                            ];
                      if (channels.isEmpty &&
                          results.movies.isEmpty &&
                          results.series.isEmpty) {
                        return _CenteredHint(
                          icon: Icons.search_off_rounded,
                          text: 'No results for “$_query”',
                        );
                      }
                      final query = key.$2;
                      void open(MediaItem item) => _open(item, query: query);
                      return ListView(
                        padding: const EdgeInsets.only(bottom: 32),
                        children: [
                          ContentRail(
                            title: 'Live Channels',
                            wide: true,
                            items: channels.map(searchChannelItem).toList(),
                            formFactor: formFactor,
                            onSelect: open,
                          ),
                          ContentRail(
                            title: 'Movies',
                            items: results.movies.map(searchMovieItem).toList(),
                            formFactor: formFactor,
                            onSelect: open,
                          ),
                          ContentRail(
                            title: 'Series',
                            items: results.series
                                .map(searchSeriesItem)
                                .toList(),
                            formFactor: formFactor,
                            onSelect: open,
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CenteredHint extends StatelessWidget {
  const _CenteredHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: AppColors.textSecondary),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
