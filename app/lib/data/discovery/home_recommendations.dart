import 'home_feed.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/media_item.dart';
import '../db/app_database.dart';
import '../providers.dart';
import 'discovery_repository.dart';
import 'title_identity.dart';
import 'trakt_client.dart';

enum RecommendationReason { saved, watching, watched }

typedef ActivityTitle = (CatalogKind, int);
typedef RecommendationRail = ({
  ActivityTitle seed,
  String title,
  List<MediaItem> items,
});

final _activityProvider = FutureProvider.autoDispose
    .family<Map<RecommendationReason, List<ActivityTitle>>, int>((
      ref,
      source,
    ) async {
      final activity = await ref.watch(homeActivityProvider(source).future);
      final groups = {
        for (final reason in RecommendationReason.values)
          reason: <ActivityTitle>[],
      };
      final playbackSeen = <ActivityTitle>{};
      for (final event in activity) {
        final reason = RecommendationReason.values.byName(event.signal.name);
        if (reason == RecommendationReason.saved ||
            playbackSeen.add(event.key)) {
          groups[reason]!.add(event.key);
        }
      }
      return groups;
    });

final homePicksProvider = FutureProvider.autoDispose
    .family<RecommendationRail?, (int, RecommendationReason)>((
      ref,
      query,
    ) async {
      final (source, reason) = query;
      final repo = ref.watch(discoveryRepositoryProvider);
      ref.watch(activeSourceProvider.select((v) => v.value?.lastSyncAt));
      final groups = await ref.watch(_activityProvider(source).future);
      final seeds = groups[reason]!;
      final elsewhere = {
        for (final entry in groups.entries)
          if (entry.key != reason) ...entry.value,
      };
      final known = {for (final values in groups.values) ...values};
      // Prefer distinct reasons when a title is both saved and in progress.
      final ordered = [
        ...seeds.where((s) => !elsewhere.contains(s)),
        ...seeds.where(elsewhere.contains),
      ];
      for (final seed in ordered.take(5)) {
        if (!ref.mounted) return null;
        final (kind, id) = seed;
        CatalogTitle? key;
        if (kind == CatalogKind.series) {
          final show = await repo.db.getSeriesItem(source, id);
          if (show != null) key = seriesKey(show);
        } else {
          final movie = await repo.db.getMovie(source, id);
          if (movie != null) key = movieKey(movie);
        }
        if (key == null || !ref.mounted) continue;
        final details = await repo.load(key);
        if (!ref.mounted) return null;
        final items = await repo.recommendations(
          key,
          details,
          excluded: {
            for (final (type, item) in known)
              if (type == kind) item,
          },
        );
        if (items.isEmpty) continue;
        final name = details?.title.name ?? splitTitle(key.name).name;
        final title = switch (reason) {
          RecommendationReason.saved => 'Because you saved $name',
          RecommendationReason.watching => 'Because you’re watching $name',
          RecommendationReason.watched when kind == CatalogKind.series =>
            'Because you watched an episode of $name',
          RecommendationReason.watched => 'Because you watched $name',
        };
        return (seed: seed, title: title, items: items);
      }
      return null;
    });
