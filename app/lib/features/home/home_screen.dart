import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/media_item.dart';
import '../../core/app_platform.dart';
import '../../core/responsive/form_factor.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/backend/backend_providers.dart';
import '../../data/providers.dart';
import '../details/media_navigation.dart';
import '../live/live_widgets.dart';
import 'widgets/content_rail.dart';
import 'widgets/hero_banner.dart';
import 'widgets/home_spotlight.dart';
import 'widgets/home_remote_navigation.dart';
import 'widgets/top_charts_section.dart';
import '../../data/discovery/home_feed.dart';

const _welcomeHero = MediaItem(
  title: 'Welcome to Zauxoflix',
  subtitle:
      'Your catalog is loading. Movies, series and live TV from your '
      'playlist will appear here.',
);

EdgeInsets _homeScrollPadding(BuildContext context, FormFactor formFactor) =>
    EdgeInsets.only(
      bottom:
          32 +
          (formFactor == FormFactor.mobile
              ? MediaQuery.paddingOf(context).bottom
              : 0),
    );

final _recentHomeMovies = StreamProvider.autoDispose.family<List<Movie>, int>(
  (ref, source) => ref.watch(databaseProvider).watchRecentMovies(source),
);

final _checkSeriesProvider = Provider.autoDispose.family<void, int>((
  ref,
  sourceId,
) {
  final lastChecks = <int, DateTime>{};
  bool busy = false;
  bool active() =>
      ref.mounted &&
      ref.read(activeSourceProvider).value?.id == sourceId &&
      WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused &&
      WidgetsBinding.instance.lifecycleState != AppLifecycleState.hidden;
  Future<void> refresh() async {
    if (busy || !active() || ref.read(syncControllerProvider) is SyncRunning) {
      return;
    }
    final api = ref.read(xtreamApiProvider);
    final resume = ref.read(resumeServiceProvider);
    if (api == null || resume == null) return;
    busy = true;
    try {
      await resume.refreshCaughtUp(api.seriesInfo, lastChecks, active: active);
    } finally {
      busy = false;
    }
  }

  void schedule() => refresh().ignore();
  final timer = Timer.periodic(const Duration(minutes: 15), (_) => schedule());
  ref.onDispose(timer.cancel);
  ref.listen(syncControllerProvider, (_, state) {
    if (state is SyncSuccess) schedule();
  });
  if (isWebOsPlatform) {
    final initial = Timer(const Duration(seconds: 3), schedule);
    ref.onDispose(initial.cancel);
  } else {
    schedule();
  }
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _removeFromContinueWatching(
    BuildContext context,
    AppDatabase db,
    PlaybackPosition position,
  ) async {
    // A series shows as a single card standing in for all its episodes, so
    // removing it clears every episode's progress rather than just one.
    final wholeSeries =
        position.kind == WatchKind.episode && position.seriesId != null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Continue Watching?'),
        content: Text(
          wholeSeries
              ? '"${position.title}" and all its episodes will be removed '
                    'from this row.'
              : '"${position.title}" will be removed from this row.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (wholeSeries) {
        await db.deletePositionsForSeries(
          position.sourceId,
          position.seriesId!,
        );
      } else {
        await db.deletePosition(
          position.sourceId,
          position.kind,
          position.itemId,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formFactor = formFactorOf(context, ref);
    final auth = ref.watch(authControllerProvider);
    if (auth is Authenticated && auth.sourceRestoreFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Unable to restore your playlist. Check your connection.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref
                  .read(authControllerProvider.notifier)
                  .retrySourceRestore(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (auth is Authenticated && auth.sourceRestoring) {
      return _HomeSkeleton(formFactor: formFactor);
    }
    final source = ref.watch(activeSourceProvider).value;
    final db = ref.watch(databaseProvider);
    final syncing = ref.watch(syncControllerProvider) is SyncRunning;

    if (source == null) return _HomeSkeleton(formFactor: formFactor);
    if (auth is Authenticated && source.sourceType == SourceType.xtream) {
      ref.watch(_checkSeriesProvider(source.id));
    }

    final recent = ref.watch(_recentHomeMovies(source.id));
    return Builder(
      builder: (context) {
        if ((!isWebOsPlatform && recent.isLoading && !recent.hasValue) ||
            (syncing &&
                source.lastSyncAt == null &&
                (recent.value?.isEmpty ?? true))) {
          return _HomeSkeleton(formFactor: formFactor);
        }
        final movies = [
          for (final m in recent.value ?? const <Movie>[])
            MediaItem(
              title: m.name,
              imageUrl: m.icon,
              type: MediaType.movie,
              id: m.streamId,
              containerExtension: m.containerExtension,
            ),
        ];
        void open(MediaItem item) => openMediaItem(context, ref, item);

        final list = ListView(
          padding: _homeScrollPadding(context, formFactor),
          children: [
            HomeFocusRow(
              featured: true,
              child: HomeSpotlight(
                key: ValueKey(source.id),
                source: source.id,
                formFactor: formFactor,
                fallback: recent.value?.firstOrNull,
                welcome: _welcomeHero,
              ),
            ),
            StreamBuilder<List<PlaybackPosition>>(
              stream: db.watchContinueWatching(source.id),
              builder: (context, snapshot) {
                final positions = snapshot.data ?? const <PlaybackPosition>[];
                final items = [
                  for (final p in positions)
                    MediaItem(
                      title: p.title,
                      continueWatching: true,
                      type: p.kind == WatchKind.episode
                          ? MediaType.series
                          : MediaType.movie,
                      id: p.kind == WatchKind.episode ? p.seriesId : p.itemId,
                      subtitle: p.subtitle,
                      imageUrl: p.imageUrl,
                      progress: p.durationSecs <= 0
                          ? null
                          : p.positionSecs / p.durationSecs,
                      // Subtitle is "S2 E2 — <episode title>"; the chip only
                      // wants the season/episode part.
                      badge: p.kind == WatchKind.episode
                          ? '${p.positionSecs == 0 ? 'Next · ' : ''}${p.subtitle.split(' — ').first}'
                          : null,
                    ),
                ];
                return ContentRail(
                  title: 'Continue Watching',
                  wide: true,
                  items: items,
                  formFactor: formFactor,
                  onDetails: open,
                  onSelect: (item) => playResumable(
                    context,
                    ref,
                    positions[items.indexOf(item)],
                  ),
                  onRemove: (item) => _removeFromContinueWatching(
                    context,
                    db,
                    positions[items.indexOf(item)],
                  ),
                );
              },
            ),
            LiveForYouRail(sourceId: source.id, formFactor: formFactor),
            Consumer(
              builder: (context, ref, _) {
                final feed = ref.watch(homeDisplayFeedProvider(source.id));
                return Column(
                  children: [
                    for (final movies in [true, false])
                      ContentRail(
                        key: ValueKey((source.id, movies)),
                        title: movies
                            ? 'Recommended movies'
                            : 'Recommended series',
                        items:
                            (movies ? feed?.movies : feed?.series) ?? const [],
                        formFactor: formFactor,
                        onSelect: open,
                      ),
                  ],
                );
              },
            ),
            TopChartsSection(
              key: ValueKey((source.id, 'charts')),
              source: source.id,
              formFactor: formFactor,
              loadWhenVisible: isWebOsPlatform,
            ),
            StreamBuilder<List<Favorite>>(
              stream: db.watchFavorites(source.id),
              builder: (context, snapshot) => ContentRail(
                title: 'My List',
                items: [
                  for (final f in snapshot.data ?? const <Favorite>[])
                    MediaItem(
                      title: f.name,
                      imageUrl: f.imageUrl,
                      type: switch (f.kind) {
                        CatalogKind.live => MediaType.live,
                        CatalogKind.vod => MediaType.movie,
                        CatalogKind.series => MediaType.series,
                      },
                      id: f.itemId,
                    ),
                ],
                formFactor: formFactor,
                onSelect: open,
              ),
            ),
            ContentRail(
              title: 'Recently Added Movies',
              items: movies,
              formFactor: formFactor,
              loading: recent.isLoading && !recent.hasValue,
              onSelect: open,
            ),
            StreamBuilder<List<SeriesItem>>(
              stream: db.watchRecentSeries(source.id),
              builder: (context, snapshot) => ContentRail(
                title: 'New Series',
                items: [
                  for (final s in snapshot.data ?? const <SeriesItem>[])
                    MediaItem(
                      title: s.name,
                      imageUrl: s.cover,
                      type: MediaType.series,
                      id: s.seriesId,
                    ),
                ],
                formFactor: formFactor,
                loading: !snapshot.hasData,
                onSelect: open,
              ),
            ),
          ],
        );
        return formFactor.isTv
            ? HomeRemoteNavigation(key: ValueKey(source.id), child: list)
            : list;
      },
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton({required this.formFactor});

  final FormFactor formFactor;

  @override
  Widget build(BuildContext context) => ListView(
    padding: _homeScrollPadding(context, formFactor),
    children: [
      HeroBanner(item: _welcomeHero, formFactor: formFactor, loading: true),
      for (final (title, wide) in const [
        ('Recently Added Movies', false),
        ('New Series', false),
        ('Live for you', true),
      ])
        ContentRail(
          title: title,
          items: const [],
          formFactor: formFactor,
          loading: true,
          wide: wide,
        ),
    ],
  );
}
