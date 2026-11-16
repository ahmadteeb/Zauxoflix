import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/media_item.dart';
import '../../core/responsive/form_factor.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../data/xtream/xtream_models.dart';
import '../details/media_navigation.dart';
import 'widgets/content_rail.dart';
import 'widgets/hero_banner.dart';

const _welcomeHero = MediaItem(
  title: 'Welcome to Zauxoflix',
  subtitle:
      'Your catalog is loading. Movies, series and live TV from your '
      'playlist will appear here.',
);

/// Detail fetch for the featured movie (plot, year, genre…). Cached per
/// stream id so hero rebuilds don't re-hit the panel; failures just leave
/// the metadata blank.
final _heroInfoProvider = FutureProvider.family<XtreamVodInfo?, int>((
  ref,
  streamId,
) async {
  final api = ref.watch(xtreamApiProvider);
  if (api == null) return null;
  try {
    return await api.vodInfo(streamId);
  } on Object {
    return null;
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
    final source = ref.watch(activeSourceProvider).value;
    final db = ref.watch(databaseProvider);

    if (source == null) {
      // Router redirects to setup; avoid flashing mock content meanwhile.
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<Movie>>(
      stream: db.watchRecentMovies(source.id),
      builder: (context, moviesSnapshot) {
        final movies = [
          for (final m in moviesSnapshot.data ?? const <Movie>[])
            MediaItem(
              title: m.name,
              imageUrl: m.icon,
              type: MediaType.movie,
              id: m.streamId,
              containerExtension: m.containerExtension,
            ),
        ];
        final heroMovie = (moviesSnapshot.data?.isNotEmpty ?? false)
            ? moviesSnapshot.data!.first
            : null;
        final heroInfo = heroMovie == null
            ? null
            : ref.watch(_heroInfoProvider(heroMovie.streamId)).value;
        final hero = heroMovie == null
            ? _welcomeHero
            : MediaItem(
                title: heroMovie.name,
                subtitle: heroInfo?.plot ?? '',
                imageUrl: heroInfo?.backdrop ?? heroMovie.icon,
                type: MediaType.movie,
                id: heroMovie.streamId,
                containerExtension: heroMovie.containerExtension,
              );
        final heroMeta = heroMovie == null
            ? ''
            : [
                if (heroMovie.rating case final r? when r > 0)
                  '★ ${r.toStringAsFixed(1)}',
                if (heroInfo?.releaseDate case final d? when d.isNotEmpty)
                  d.split('-').first,
                ?heroInfo?.durationText,
                ?heroInfo?.genre,
              ].join('  ·  ');
        void open(MediaItem item) => openMediaItem(context, ref, item);

        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            StreamBuilder<bool>(
              stream: hero.id == null
                  ? null
                  : db.watchIsFavorite(source.id, CatalogKind.vod, hero.id!),
              builder: (context, favSnapshot) {
                final inList = favSnapshot.data ?? false;
                return HeroBanner(
                  item: hero,
                  formFactor: formFactor,
                  metaLine: heroMeta,
                  onPlay: hero.id == null ? null : () => open(hero),
                  inMyList: inList,
                  onToggleMyList: hero.id == null
                      ? null
                      : () => inList
                            ? db.removeFavorite(
                                source.id,
                                CatalogKind.vod,
                                hero.id!,
                              )
                            : db.addFavorite(
                                sourceId: source.id,
                                kind: CatalogKind.vod,
                                itemId: hero.id!,
                                name: hero.title,
                                imageUrl: hero.imageUrl,
                              ),
                );
              },
            ),
            StreamBuilder<List<PlaybackPosition>>(
              stream: db.watchContinueWatching(source.id),
              builder: (context, snapshot) {
                final positions = snapshot.data ?? const <PlaybackPosition>[];
                final items = [
                  for (final p in positions)
                    MediaItem(
                      title: p.title,
                      subtitle: p.subtitle,
                      imageUrl: p.imageUrl,
                      progress: p.durationSecs <= 0
                          ? 0
                          : p.positionSecs / p.durationSecs,
                      // Subtitle is "S2 E2 — <episode title>"; the chip only
                      // wants the season/episode part.
                      badge: p.kind == WatchKind.episode
                          ? p.subtitle.split(' — ').first
                          : null,
                    ),
                ];
                return ContentRail(
                  title: 'Continue Watching',
                  items: items,
                  formFactor: formFactor,
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
              loading: !moviesSnapshot.hasData,
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
            StreamBuilder<List<LiveChannel>>(
              stream: db.watchLiveChannels(source.id, limit: 20),
              builder: (context, snapshot) => ContentRail(
                title: 'Live Channels',
                wide: true,
                items: [
                  for (final c in snapshot.data ?? const <LiveChannel>[])
                    MediaItem(
                      title: c.name,
                      subtitle: c.channelNumber == null
                          ? ''
                          : 'CH ${c.channelNumber}',
                      imageUrl: c.icon,
                      type: MediaType.live,
                      id: c.streamId,
                    ),
                ],
                formFactor: formFactor,
                loading: !snapshot.hasData,
                onSelect: open,
              ),
            ),
          ],
        );
      },
    );
  }
}
