import '../../data/discovery/discovery_repository.dart';
import '../../data/discovery/title_identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/form_factor.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/catalog_row_card.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/backend/remote_models.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../data/xtream/xtream_api.dart';
import '../../data/xtream/xtream_models.dart';
import '../downloads/download_button.dart';
import '../player/player_catalog.dart';
import '../remote/cast_session.dart';
import '../remote/device_picker.dart';
import 'details_widgets.dart';

class SeriesDetailsScreen extends ConsumerStatefulWidget {
  const SeriesDetailsScreen({super.key, required this.seriesId});

  final int seriesId;

  @override
  ConsumerState<SeriesDetailsScreen> createState() =>
      _SeriesDetailsScreenState();
}

class _SeriesDetailsScreenState extends ConsumerState<SeriesDetailsScreen> {
  int? _season;
  (int, int)? _catalogKey;
  // Memoized so season switches (setState) don't recreate the futures and
  // refetch/flash the whole page.
  Future<SeriesItem?>? _seriesFuture;

  void _playEpisode(
    XtreamApi api,
    SeriesItem series,
    List<XtreamEpisode> episodes,
    int index, {
    PlaybackPosition? position,
  }) {
    startPlayback(
      context,
      ref,
      seasonPlayback(
        api,
        series,
        episodes,
        index,
        ref.read(resumeServiceProvider),
        position: position,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(activeSourceProvider).value;
    final api = ref.watch(xtreamApiProvider);
    if (source == null || api == null) return const SizedBox.shrink();
    final db = ref.watch(databaseProvider);
    final seriesInfo = ref.watch(playerSeriesProvider(widget.seriesId).future);

    final key = (source.id, widget.seriesId);
    if (_catalogKey != key) {
      _catalogKey = key;
      _seriesFuture = db.getSeriesItem(source.id, widget.seriesId);
      _season = null;
    }

    return Scaffold(
      body: FutureBuilder(
        key: ValueKey(key),
        future: _seriesFuture,
        builder: (context, seriesSnapshot) {
          final series = seriesSnapshot.data;
          if (series == null) {
            return seriesSnapshot.connectionState == ConnectionState.waiting
                ? const DetailsSkeleton()
                : const Center(child: Text('Series not found'));
          }
          return FutureBuilder(
            // Attach the error listener as soon as the episode request starts.
            future: seriesInfo,
            builder: (context, infoSnapshot) {
              final info = infoSnapshot.data;
              final loading =
                  infoSnapshot.connectionState == ConnectionState.waiting;
              final seasonNumbers = (info?.seasons.keys.toList() ?? [])..sort();

              return StreamBuilder(
                stream: db.watchSeriesPositions(source.id, widget.seriesId),
                builder: (context, positionsSnapshot) {
                  final positions =
                      positionsSnapshot.data ?? const <PlaybackPosition>[];
                  final latest = positions.firstOrNull;
                  final resume = latest?.isCompletedEpisode == true
                      ? null
                      : latest;
                  final positionsById = {
                    for (final p in positions)
                      if (!p.isCompletedEpisode) p.itemId: p,
                  };
                  // Locate the resume episode in the loaded seasons; a stale
                  // position for a removed episode falls back to Play.
                  List<XtreamEpisode>? resumeEpisodes;
                  var resumeIndex = 0;
                  if (resume != null && info != null) {
                    for (final seasonEpisodes in info.seasons.values) {
                      final i = seasonEpisodes.indexWhere(
                        (e) => e.id == resume.itemId,
                      );
                      if (i >= 0) {
                        resumeEpisodes = seasonEpisodes;
                        resumeIndex = i;
                        break;
                      }
                    }
                  }
                  final resumeEpisode = resumeEpisodes?[resumeIndex];

                  // Land on the season being watched; manual chip selection
                  // still wins once the user has tapped one.
                  final selectedSeason =
                      _season ??
                      resumeEpisode?.season ??
                      (seasonNumbers.isEmpty ? null : seasonNumbers.first);
                  final episodes = selectedSeason == null
                      ? const <XtreamEpisode>[]
                      : info!.seasons[selectedSeason] ??
                            const <XtreamEpisode>[];
                  final firstEpisode = episodes.isEmpty ? null : episodes.first;

                  return StreamBuilder(
                    stream: db.watchIsFavorite(
                      source.id,
                      CatalogKind.series,
                      widget.seriesId,
                    ),
                    builder: (context, favSnapshot) {
                      final favorite = favSnapshot.data ?? false;
                      return DetailsScaffold(
                        title: series.name,
                        discoveryKey: seriesKey(
                          series,
                          year: titleYear(info?.releaseDate),
                          external: info?.externalId,
                        ),
                        providerScore: providerRating(
                          series.rating,
                          series.ratingScale,
                        ),
                        posterUrl: series.cover,
                        backdropUrl: series.cover,
                        metaLine: [
                          if ((titleYear(info?.releaseDate) ??
                                  series.releaseYear)
                              case final year?)
                            '$year',
                          ?info?.genre,
                          if (seasonNumbers.isNotEmpty)
                            '${seasonNumbers.length} season'
                                '${seasonNumbers.length == 1 ? '' : 's'}',
                        ].join('  ·  '),
                        plot: info?.plot ?? series.plot,
                        cast: info?.cast,
                        loadingDetails: loading,
                        playLabel: resumeEpisode != null
                            ? '${resume!.positionSecs > 0 ? 'Resume' : 'Play'} S${resumeEpisode.season} '
                                  'E${resumeEpisode.episodeNum}'
                            : firstEpisode == null
                            ? 'Play'
                            : 'Play S$selectedSeason '
                                  'E${firstEpisode.episodeNum}',
                        playProgress: resumeEpisode == null
                            ? null
                            : _fractionWatched(resume),
                        favorite: favorite,
                        onToggleFavorite: () => favorite
                            ? db.removeFavorite(
                                source.id,
                                CatalogKind.series,
                                widget.seriesId,
                              )
                            : db.addFavorite(
                                sourceId: source.id,
                                kind: CatalogKind.series,
                                itemId: widget.seriesId,
                                name: series.name,
                                imageUrl: series.cover,
                              ),
                        onCast:
                            kTvBuild || (resumeEpisode ?? firstEpisode) == null
                            ? null
                            : () {
                                final episode = resumeEpisode ?? firstEpisode!;
                                castFromDetails(
                                  context,
                                  ref,
                                  identity: PlaybackIdentity(
                                    itemType: 'SERIES',
                                    itemId: '${widget.seriesId}',
                                    episodeId: '${episode.id}',
                                  ),
                                  positionSec: resumeEpisode != null
                                      ? resume!.positionSecs
                                      : 0,
                                );
                              },
                        onPlay: resumeEpisodes != null
                            ? () => _playEpisode(
                                api,
                                series,
                                resumeEpisodes!,
                                resumeIndex,
                                position: resume,
                              )
                            : firstEpisode == null
                            ? null
                            : () => _playEpisode(api, series, episodes, 0),
                        episodesBuilder: (showHeading) => loading
                            ? const EpisodesSkeleton()
                            : infoSnapshot.hasError
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Could not load episodes — check your connection.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => ref.invalidate(
                                      playerSeriesProvider(widget.seriesId),
                                    ),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              )
                            : _EpisodeList(
                                showHeading: showHeading,
                                seasonNumbers: seasonNumbers,
                                selectedSeason: selectedSeason,
                                episodes: episodes,
                                positionsById: positionsById,
                                onSeasonChanged: (s) =>
                                    setState(() => _season = s),
                                onEpisodeSelected: (i) => _playEpisode(
                                  api,
                                  series,
                                  episodes,
                                  i,
                                  position: positionsById[episodes[i].id],
                                ),
                                downloadButtonFor: kTvBuild
                                    ? null
                                    : (e) => DownloadButton(
                                        compact: true,
                                        sourceId: source.id,
                                        kind: WatchKind.episode,
                                        itemId: e.id,
                                        seriesId: widget.seriesId,
                                        title: series.name,
                                        subtitle:
                                            'S${e.season} E${e.episodeNum}'
                                            ' — ${e.title}',
                                        imageUrl: series.cover ?? e.image,
                                        episodeImageUrl: e.image,
                                        containerExtension:
                                            e.containerExtension,
                                        url: api.seriesEpisodeUrl(
                                          e.id,
                                          e.containerExtension,
                                        ),
                                      ),
                              ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

double? _fractionWatched(PlaybackPosition? position) {
  if (position == null || position.durationSecs <= 0) return null;
  return (position.positionSecs / position.durationSecs).clamp(0.0, 1.0);
}

class _EpisodeList extends StatelessWidget {
  final bool showHeading;
  const _EpisodeList({
    required this.showHeading,
    required this.seasonNumbers,
    required this.selectedSeason,
    required this.episodes,
    required this.positionsById,
    required this.onSeasonChanged,
    required this.onEpisodeSelected,
    this.downloadButtonFor,
  });

  final List<int> seasonNumbers;
  final int? selectedSeason;
  final List<XtreamEpisode> episodes;
  final Map<int, PlaybackPosition> positionsById;
  final ValueChanged<int> onSeasonChanged;
  final ValueChanged<int> onEpisodeSelected;
  final Widget Function(XtreamEpisode episode)? downloadButtonFor;

  @override
  Widget build(BuildContext context) {
    if (seasonNumbers.isEmpty) {
      return const Text(
        'No episodes listed for this series.',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }
    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeading)
            const Text(
              'EPISODES',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          if (showHeading) const SizedBox(height: 10),
          if (seasonNumbers.length > 1)
            SizedBox(
              height: MediaQuery.textScalerOf(context).scale(16) + 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: seasonNumbers.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final season = seasonNumbers[i];
                  final selected = season == selectedSeason;
                  return FilterChip(
                    selected: selected,
                    showCheckmark: false,
                    label: Text('Season $season'),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => onSeasonChanged(season),
                  );
                },
              ),
            ),
          const SizedBox(height: 10),
          for (final (i, episode) in episodes.indexed)
            _EpisodeTile(
              episode: episode,
              progress: _fractionWatched(positionsById[episode.id]),
              onSelect: () => onEpisodeSelected(i),
              trailing: downloadButtonFor?.call(episode),
            ),
        ],
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({
    required this.episode,
    required this.onSelect,
    this.progress,
    this.trailing,
  });

  final XtreamEpisode episode;
  final VoidCallback onSelect;
  final double? progress;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return CatalogRowCard(
      title: episode.title,
      onSelect: onSelect,
      caption: [
        'Episode ${episode.episodeNum}',
        if (episode.durationText?.isNotEmpty == true) episode.durationText!,
      ].join(' · '),
      description: episode.plot,
      image: episode.image,
      icon: Icons.movie_outlined,
      progress: progress,
      trailing: trailing,
    );
  }
}
