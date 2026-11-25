import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:drift/drift.dart' show BooleanExpressionOperators;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backend/backend_providers.dart';
import '../db/app_database.dart';
import '../providers.dart';
import 'live_directory.dart';
import 'regional_channels.dart';

Future<LiveDirectory> buildLiveDirectoryInBackground(
  List<LiveChannel> rows,
  List<Category> categories,
) => rows.isEmpty
    ? Future.value(LiveDirectory(const []))
    : Isolate.run(() => buildLiveDirectory(rows, categories));

final liveDirectoryProvider = StreamProvider.autoDispose
    .family<LiveDirectory, int>((ref, sourceId) {
      final db = ref.watch(databaseProvider);
      final result = StreamController<LiveDirectory>();
      var revision = 0;
      Future<void> refresh(List<LiveChannel> rows, int version) async {
        try {
          final categories = rows.isEmpty
              ? const <Category>[]
              : await (db.select(db.categories)..where(
                      (category) =>
                          category.sourceId.equals(sourceId) &
                          category.kind.equalsValue(CatalogKind.live),
                    ))
                    .get();
          if (result.isClosed || version != revision) return;
          final directory = await buildLiveDirectoryInBackground(
            rows,
            categories,
          );
          if (!result.isClosed && version == revision) result.add(directory);
        } catch (error, stack) {
          if (!result.isClosed && version == revision) {
            result.addError(error, stack);
          }
        }
      }

      // Cancel the DB subscription immediately on branch teardown even if an
      // isolate still owns a previous catalog snapshot.
      final subscription = db
          .watchLiveChannels(sourceId, limit: null)
          .listen(
            (rows) => unawaited(refresh(rows, ++revision)),
            onError: result.addError,
          );
      ref.onDispose(() {
        unawaited(subscription.cancel());
        unawaited(result.close());
      });
      return result.stream;
    });

final liveViewerProvider = Provider<String?>((ref) {
  final auth = ref.watch(authControllerProvider);
  return auth is Authenticated ? auth.user.id : null;
});

final liveRegionProvider =
    AsyncNotifierProvider<LiveRegionPreference, LiveRegion>(
      LiveRegionPreference.new,
    );

class LiveRegionPreference extends AsyncNotifier<LiveRegion> {
  String _key(String? viewer) => 'live.region.${viewer ?? 'device'}';

  @override
  Future<LiveRegion> build() async {
    final viewer = ref.watch(liveViewerProvider);
    try {
      final saved = await SharedPreferencesAsync().getString(_key(viewer));
      return LiveRegion.values
              .where((region) => region.name == saved)
              .firstOrNull ??
          LiveRegion.jordan;
    } on Exception {
      return LiveRegion.jordan;
    }
  }

  Future<void> select(LiveRegion region) async {
    final viewer = ref.read(liveViewerProvider);
    state = AsyncData(region);
    try {
      await SharedPreferencesAsync().setString(_key(viewer), region.name);
    } on Exception {
      // The in-memory selection remains available for this session.
    }
  }
}

final liveTuningProvider = StreamProvider.autoDispose
    .family<Map<String, LiveTuningData>, int>((ref, sourceId) {
      final viewer = ref.watch(liveViewerProvider);
      if (viewer == null) return Stream.value(const {});
      return ref
          .watch(databaseProvider)
          .watchLiveTuning(sourceId, viewer)
          .map((rows) => {for (final row in rows) row.channelKey: row});
    });

final liveGuideIdsProvider = StreamProvider.autoDispose
    .family<Map<String, String>, int>(
      (ref, sourceId) => ref
          .watch(databaseProvider)
          .watchLiveGuideLinks(sourceId)
          .map((rows) => {for (final row in rows) row.channelKey: row.guideId}),
    );

typedef _LiveRank = ({int seconds, double decayed, DateTime lastWatched});

class LiveRecommendations {
  const LiveRecommendations(
    this.forYou,
    this.mostWatched,
    this.favorites,
    this.recent,
    this.minutes,
  );
  final List<LiveStation> forYou, mostWatched, favorites, recent;
  final Map<String, int> minutes;
}

LiveRecommendations rankLiveStations({
  required LiveDirectory directory,
  required LiveRegion region,
  required List<LiveViewingData> history,
  required List<LiveChannel> favorites,
  required List<LiveChannel> recent,
  required DateTime now,
}) {
  final today = AppDatabase.liveDay(now);
  final scores = <String, _LiveRank>{};
  final genres = <LiveGenre, double>{};
  for (final view in history) {
    final age = today - view.day;
    final station = directory.byStream[view.streamId];
    if (age < 0 || age > 29 || station == null) continue;
    final prior = scores[station.key];
    final weight = view.seconds * math.pow(.5, age / 14).toDouble();
    scores[station.key] = (
      seconds: (prior?.seconds ?? 0) + view.seconds,
      decayed: (prior?.decayed ?? 0) + weight,
      lastWatched: prior == null || prior.lastWatched.isBefore(view.lastWatched)
          ? view.lastWatched
          : prior.lastWatched,
    );
    if (station.genre case final kind?) {
      genres.update(kind, (n) => n + weight, ifAbsent: () => weight);
    }
  }
  List<LiveStation> distinct(List<LiveChannel> raw) {
    final stations = <String, LiveStation>{};
    for (final channel in raw) {
      final station = directory.byStream[channel.streamId];
      if (station != null) stations[station.key] = station;
    }
    return stations.values.toList();
  }

  final saved = distinct(favorites);
  final last = distinct(recent);
  final local = directory.regional(region);
  final regional = directory.regional(LiveRegion.middleEast);
  final ranked = scores.entries.toList()
    ..sort((a, b) {
      final size = b.value.seconds.compareTo(a.value.seconds);
      if (size != 0) return size;
      final time = b.value.lastWatched.compareTo(a.value.lastWatched);
      return time != 0 ? time : a.key.compareTo(b.key);
    });
  final candidates = {
    for (final station in [...saved, ...last, ...local, ...regional])
      station.key: station,
    for (final item in ranked) item.key: directory.byKey[item.key]!,
  };
  final savedKeys = saved.map((s) => s.key).toSet();
  final recentPosition = {
    for (final (index, station) in last.indexed) station.key: index,
  };
  final localKeys = local.map((s) => s.key).toSet();
  final largest = scores.values.fold<double>(
    1,
    (n, entry) => math.max(n, entry.decayed),
  );
  final largestGenre = genres.values.fold<double>(1, math.max);
  double relevance(LiveStation station) =>
      42 * (scores[station.key]?.decayed ?? 0) / largest +
      (savedKeys.contains(station.key) ? 24 : 0) +
      (switch (recentPosition[station.key]) {
        final int index => 18 / (index + 1),
        null => 0,
      }) +
      10 * (genres[station.genre] ?? 0) / largestGenre +
      (localKeys.contains(station.key) ? 8 : 0);
  final weighted = candidates.values.toList().indexed.toList()
    ..sort((a, b) {
      final score = relevance(b.$2).compareTo(relevance(a.$2));
      return score != 0 ? score : a.$1.compareTo(b.$1);
    });
  final picked = <LiveStation>[];
  final later = <LiveStation>[];
  for (final (_, station) in weighted) {
    // A second genre gets a chance near the front without suppressing
    // further channels from very large sports or news families.
    if (picked.length < 8 &&
        station.genre != null &&
        picked.reversed.take(2).where((s) => s.genre == station.genre).length ==
            2) {
      later.add(station);
    } else {
      picked.add(station);
    }
  }
  return LiveRecommendations(
    [...picked, ...later],
    [for (final item in ranked) directory.byKey[item.key]!],
    saved,
    last,
    {for (final item in ranked) item.key: item.value.seconds ~/ 60},
  );
}

final _liveHistory = StreamProvider.autoDispose
    .family<List<LiveViewingData>, (int, String)>(
      (ref, key) =>
          ref.watch(databaseProvider).watchLiveViewing(key.$1, key.$2),
    );
final _liveCollections = StreamProvider.autoDispose
    .family<List<LiveChannel>, (int, LiveCollection)>(
      (ref, key) =>
          ref.watch(databaseProvider).watchChannelCollection(key.$1, key.$2),
    );

final liveRecommendationsProvider = Provider.autoDispose
    .family<LiveRecommendations?, int>((ref, sourceId) {
      final directory = ref.watch(liveDirectoryProvider(sourceId)).value;
      if (directory == null) return null;
      final viewer = ref.watch(liveViewerProvider);
      final region = ref.watch(liveRegionProvider).value ?? LiveRegion.jordan;
      return rankLiveStations(
        directory: directory,
        region: region,
        history: viewer == null
            ? const []
            : ref.watch(_liveHistory((sourceId, viewer))).value ?? const [],
        favorites:
            ref
                .watch(_liveCollections((sourceId, LiveCollection.favorites)))
                .value ??
            const [],
        recent:
            ref
                .watch(_liveCollections((sourceId, LiveCollection.recent)))
                .value ??
            const [],
        now: DateTime.now(),
      );
    });

final liveScheduleProvider = FutureProvider.autoDispose
    .family<List<EpgProgramme>, (int, String)>((ref, key) {
      ref.watch(syncControllerProvider);
      final timer = Timer(const Duration(minutes: 1), ref.invalidateSelf);
      ref.onDispose(timer.cancel);
      return ref
          .watch(databaseProvider)
          .upcomingFor(key.$1, key.$2, DateTime.now(), limit: 3);
    });

final liveSportsProvider = Provider.autoDispose
    .family<List<LiveSportsSection>, int>((ref, sourceId) {
      final directory = ref.watch(liveDirectoryProvider(sourceId)).value;
      if (directory == null) return const [];
      return directory.sports(
        mostWatched:
            ref.watch(liveRecommendationsProvider(sourceId))?.mostWatched ??
            const [],
        guideLinks: ref.watch(liveGuideIdsProvider(sourceId)).value ?? const {},
        nowPlaying: ref.watch(nowPlayingProvider).value ?? const {},
        now: DateTime.now(),
      );
    });
