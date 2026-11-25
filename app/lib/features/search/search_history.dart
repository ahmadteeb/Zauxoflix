import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/media_item.dart';
import '../../data/backend/backend_providers.dart';
import '../../data/catalog_search.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';

typedef SearchHistoryScope = ({String viewer, int sourceId});
typedef SearchResultRef = ({MediaType type, int id});

final searchHistoryScopeProvider = Provider<SearchHistoryScope?>((ref) {
  final sourceId = ref.watch(activeSourceProvider.select((s) => s.value?.id));
  if (sourceId == null) return null;
  final auth = ref.watch(authControllerProvider);
  return auth is Authenticated
      ? (viewer: auth.user.id, sourceId: sourceId)
      : null;
});

final searchHistoryProvider =
    AsyncNotifierProvider.family<
      SearchHistoryController,
      SearchHistory,
      SearchHistoryScope
    >(SearchHistoryController.new);

class SearchHistory {
  const SearchHistory({this.queries = const [], this.opened = const []});

  static const limit = 12;

  final List<String> queries;
  final List<SearchResultRef> opened;

  factory SearchHistory.decode(String? stored) {
    if (stored == null) return const SearchHistory();
    final data = jsonDecode(stored);
    if (data is! Map<String, dynamic>) return const SearchHistory();
    final queries = data['queries'];
    final opened = data['opened'];
    return SearchHistory(
      queries: queries is List
          ? queries
                .whereType<String>()
                .where((q) => catalogQuery(q).isNotEmpty)
                .take(limit)
                .toList()
          : const [],
      opened: opened is List
          ? opened.map(_decodeResult).nonNulls.take(limit).toList()
          : const [],
    );
  }

  static SearchResultRef? _decodeResult(Object? value) {
    if (value is! Map || value['id'] is! int) return null;
    final type = MediaType.values
        .where((type) => type.name == value['type'])
        .firstOrNull;
    return type == null ? null : (type: type, id: value['id'] as int);
  }

  String encode() => jsonEncode({
    'queries': queries,
    'opened': [
      for (final item in opened) {'type': item.type.name, 'id': item.id},
    ],
  });
}

class SearchHistoryController extends AsyncNotifier<SearchHistory> {
  SearchHistoryController(this.scope);

  final SearchHistoryScope scope;
  Future<void> _pending = Future.value();

  String get _key => 'search.history.${scope.viewer}.${scope.sourceId}';

  @override
  Future<SearchHistory> build() async {
    final store = ref.watch(keyValueStoreProvider);
    final stored = await store.read(_key);
    try {
      return SearchHistory.decode(stored);
    } on FormatException {
      return const SearchHistory();
    }
  }

  Future<void> record({String? query, MediaItem? item}) {
    final term = query?.trim() ?? '';
    final normalized = catalogQuery(term);
    final type = item?.type;
    final id = item?.id;
    final result = type != null && id != null ? (type: type, id: id) : null;
    if (normalized.isEmpty && result == null) return Future.value();
    return _update((history) {
      return SearchHistory(
        queries: normalized.isEmpty
            ? history.queries
            : [
                term,
                ...history.queries.where(
                  (query) => catalogQuery(query) != normalized,
                ),
              ].take(SearchHistory.limit).toList(),
        opened: result == null
            ? history.opened
            : [
                result,
                ...history.opened.where((entry) => entry != result),
              ].take(SearchHistory.limit).toList(),
      );
    });
  }

  Future<void> clear({required bool opened}) => _update(
    (history) => opened
        ? SearchHistory(queries: history.queries)
        : SearchHistory(opened: history.opened),
    requireWrite: true,
  );

  Future<void> _update(
    SearchHistory Function(SearchHistory) apply, {
    bool requireWrite = false,
  }) {
    final store = ref.read(keyValueStoreProvider);
    final mutation = _pending.then((_) async {
      if (!ref.mounted) return;
      final SearchHistory previous;
      try {
        previous = await future;
      } on Exception {
        // Avoid replacing saved history when storage could not be read.
        if (requireWrite) rethrow;
        return;
      }
      final next = apply(previous);
      try {
        await store.write(_key, next.encode());
      } on Exception {
        // Keep newly used entries available during a temporary storage failure.
        if (requireWrite) rethrow;
      }
      if (ref.mounted) state = AsyncData(next);
    });
    _pending = mutation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return mutation;
  }
}

final recentlyOpenedSearchResultsProvider = FutureProvider.autoDispose
    .family<List<MediaItem>, SearchHistoryScope>((ref, scope) async {
      final db = ref.watch(databaseProvider);
      ref.watch(activeSourceProvider.select((s) => s.value?.lastSyncAt));
      final entries = ref.watch(
        searchHistoryProvider(scope).select((value) => value.value?.opened),
      );
      if (entries == null || entries.isEmpty) return const [];
      final rows = await Future.wait<Object?>(
        entries.map(
          (entry) => switch (entry.type) {
            MediaType.live => db.getLiveChannel(scope.sourceId, entry.id),
            MediaType.movie => db.getMovie(scope.sourceId, entry.id),
            MediaType.series => db.getSeriesItem(scope.sourceId, entry.id),
          },
        ),
      );
      return rows
          .map(
            (row) => switch (row) {
              LiveChannel() => searchChannelItem(row),
              Movie() => searchMovieItem(row),
              SeriesItem() => searchSeriesItem(row),
              _ => null,
            },
          )
          .nonNulls
          .toList();
    });

MediaItem searchChannelItem(LiveChannel channel) => MediaItem(
  type: MediaType.live,
  id: channel.streamId,
  title: channel.name,
  imageUrl: channel.icon,
  subtitle: channel.channelNumber == null ? '' : 'CH ${channel.channelNumber}',
);

MediaItem searchMovieItem(Movie movie) => MediaItem(
  title: movie.name,
  imageUrl: movie.icon,
  type: MediaType.movie,
  id: movie.streamId,
  containerExtension: movie.containerExtension,
);

MediaItem searchSeriesItem(SeriesItem series) => MediaItem(
  title: series.name,
  imageUrl: series.cover,
  type: MediaType.series,
  id: series.seriesId,
);
