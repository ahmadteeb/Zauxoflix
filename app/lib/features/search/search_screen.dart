import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/input/input_modality.dart';
import '../../core/models/media_item.dart';
import '../../core/responsive/form_factor.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/dpad_text_field.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../details/media_navigation.dart';
import '../home/widgets/content_rail.dart';
import '../shell/top_nav_bar.dart';

typedef _SearchResults = ({List<Movie> movies, List<SeriesItem> series});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  Future<_SearchResults>? _results;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<_SearchResults> _search(int sourceId, String query) async {
    final db = ref.read(databaseProvider);
    return (
      movies: await db.searchMovies(sourceId, query),
      series: await db.searchSeries(sourceId, query),
    );
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = text.trim();
      if (query == _query && text.isNotEmpty) return;
      final source = ref.read(activeSourceProvider).value;
      setState(() {
        _query = query;
        _results = query.length < 2 || source == null
            ? null
            : _search(source.id, query);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final formFactor = formFactorOf(context, ref);
    final compact = formFactor == FormFactor.mobile;
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
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search movies and series…',
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
            child: _results == null
                ? const _CenteredHint(
                    icon: Icons.search_rounded,
                    text: 'Search all movies and series',
                  )
                : FutureBuilder(
                    future: _results,
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
                                  onPressed: () {
                                    final source = ref
                                        .read(activeSourceProvider)
                                        .value;
                                    if (source != null) {
                                      setState(
                                        () => _results = _search(
                                          source.id,
                                          _query,
                                        ),
                                      );
                                    }
                                  },
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
                      if (results.movies.isEmpty && results.series.isEmpty) {
                        return _CenteredHint(
                          icon: Icons.search_off_rounded,
                          text: 'No results for “$_query”',
                        );
                      }
                      void open(MediaItem item) =>
                          openMediaItem(context, ref, item);
                      return ListView(
                        padding: const EdgeInsets.only(bottom: 32),
                        children: [
                          ContentRail(
                            title: 'Movies',
                            items: [
                              for (final m in results.movies)
                                MediaItem(
                                  title: m.name,
                                  imageUrl: m.icon,
                                  type: MediaType.movie,
                                  id: m.streamId,
                                  containerExtension: m.containerExtension,
                                ),
                            ],
                            formFactor: formFactor,
                            onSelect: open,
                          ),
                          ContentRail(
                            title: 'Series',
                            items: [
                              for (final s in results.series)
                                MediaItem(
                                  title: s.name,
                                  imageUrl: s.cover,
                                  type: MediaType.series,
                                  id: s.seriesId,
                                ),
                            ],
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
