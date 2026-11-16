import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/form_factor.dart';
import '../../core/theme/app_theme.dart';
import '../../core/tv/focusable.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/backend/remote_models.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../data/xtream/xtream_api.dart';
import '../../data/xtream/xtream_models.dart';
import '../downloads/download_button.dart';
import '../player/player_screen.dart';
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
  // Memoized so season switches (setState) don't recreate the futures and
  // refetch/flash the whole page.
  Future<SeriesItem?>? _seriesFuture;
  Future<XtreamSeriesInfo>? _infoFuture;

  void _playEpisode(
    XtreamApi api,
    SeriesItem series,
    List<XtreamEpisode> episodes,
    int index, {
    Duration? startAt,
  }) {
    final resume = ref.read(resumeServiceProvider);
    startPlayback(
      context,
      ref,
      PlayerArgs(
        items: [
          for (final (i, e) in episodes.indexed)
            PlayerItem(
              url: api.seriesEpisodeUrl(e.id, e.containerExtension),
              title: series.name,
              subtitle: 'S${e.season} E${e.episodeNum} — ${e.title}',
              startAt: i == index ? startAt : null,
              identity: PlaybackIdentity(
                itemType: 'SERIES',
                itemId: '${series.seriesId}',
                episodeId: '${e.id}',
              ),
            ),
        ],
        initialIndex: index,
        onProgress: (i, position, duration) {
          final e = episodes[i];
          resume?.report(
            kind: WatchKind.episode,
            itemId: e.id,
            seriesId: series.seriesId,
            title: series.name,
            subtitle: 'S${e.season} E${e.episodeNum} — ${e.title}',
            // Series poster, not the episode still — the Continue Watching
            // card represents the whole series.
            imageUrl: series.cover ?? e.image,
            containerExtension: e.containerExtension,
            position: position,
            duration: duration,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(activeSourceProvider).value;
    final api = ref.watch(xtreamApiProvider);
    if (source == null || api == null) return const SizedBox.shrink();
    final db = ref.watch(databaseProvider);

    _seriesFuture ??= db.getSeriesItem(source.id, widget.seriesId);
    // Errors leave the metadata/episodes blank instead of surfacing an
    // unhandled exception: this future may have no listener yet (or ever,
    // when the series row is missing) while the outer FutureBuilder waits.
    _infoFuture ??= api
        .seriesInfo(widget.seriesId)
        .catchError((Object _) => const XtreamSeriesInfo(seasons: {}));

    return Scaffold(
      body: FutureBuilder(
        future: _seriesFuture,
        builder: (context, seriesSnapshot) {
          final series = seriesSnapshot.data;
          if (series == null) {
            return seriesSnapshot.connectionState == ConnectionState.waiting
                ? const DetailsSkeleton()
                : const Center(child: Text('Series not found'));
          }
          return FutureBuilder(
            future: _infoFuture,
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
                  final resume = positions.firstOrNull;
                  final progressByEpisodeId = {
                    for (final p in positions)
                      if (p.durationSecs > 0)
                        p.itemId: (p.positionSecs / p.durationSecs).clamp(
                          0.0,
                          1.0,
                        ),
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
                        posterUrl: series.cover,
                        backdropUrl: series.cover,
                        metaLine: [
                          if (series.rating != null)
                            '★ ${series.rating!.toStringAsFixed(1)}',
                          if (info?.releaseDate case final d?)
                            d.split('-').first,
                          ?info?.genre,
                          if (seasonNumbers.isNotEmpty)
                            '${seasonNumbers.length} season'
                                '${seasonNumbers.length == 1 ? '' : 's'}',
                        ].join('  ·  '),
                        plot: info?.plot ?? series.plot,
                        cast: info?.cast,
                        loadingDetails: loading,
                        playLabel: resumeEpisode != null
                            ? 'Resume S${resumeEpisode.season} '
                                  'E${resumeEpisode.episodeNum}'
                            : firstEpisode == null
                            ? 'Play'
                            : 'Play S$selectedSeason '
                                  'E${firstEpisode.episodeNum}',
                        playProgress:
                            resumeEpisode == null ||
                                resume == null ||
                                resume.durationSecs <= 0
                            ? null
                            : (resume.positionSecs / resume.durationSecs).clamp(
                                0.0,
                                1.0,
                              ),
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
                                startAt: Duration(
                                  seconds: resume!.positionSecs,
                                ),
                              )
                            : firstEpisode == null
                            ? null
                            : () => _playEpisode(api, series, episodes, 0),
                        bottom: infoSnapshot.hasError
                            ? const Text(
                                'Could not load episodes — check your '
                                'connection.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              )
                            : loading || info == null
                            ? const EpisodesSkeleton()
                            : _EpisodeList(
                                seasonNumbers: seasonNumbers,
                                selectedSeason: selectedSeason,
                                episodes: episodes,
                                progressByEpisodeId: progressByEpisodeId,
                                onSeasonChanged: (s) =>
                                    setState(() => _season = s),
                                onEpisodeSelected: (i) =>
                                    _playEpisode(api, series, episodes, i),
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

class _EpisodeList extends StatelessWidget {
  const _EpisodeList({
    required this.seasonNumbers,
    required this.selectedSeason,
    required this.episodes,
    required this.progressByEpisodeId,
    required this.onSeasonChanged,
    required this.onEpisodeSelected,
    this.downloadButtonFor,
  });

  final List<int> seasonNumbers;
  final int? selectedSeason;
  final List<XtreamEpisode> episodes;
  final Map<int, double> progressByEpisodeId;
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
          const Text(
            'EPISODES',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
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
              progress: progressByEpisodeId[episode.id],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Focusable(
        onSelect: onSelect,
        focusScale: 1.01,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '${episode.episodeNum}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width < 500 ? 72 : 128,
                  height: MediaQuery.sizeOf(context).width < 500 ? 48 : 72,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      episode.image == null
                          ? const ColoredBox(
                              color: AppColors.surfaceLight,
                              child: Icon(
                                Icons.movie_outlined,
                                size: 22,
                                color: AppColors.textSecondary,
                              ),
                            )
                          : AppImage(
                              url: episode.image!,
                              memCacheWidth: 256,
                              placeholderIconSize: 20,
                            ),
                      if (progress case final progress?)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 3,
                            backgroundColor: Colors.black54,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      episode.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (episode.plot != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        episode.plot!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (episode.durationText != null &&
                  MediaQuery.sizeOf(context).width >= 600)
                Text(
                  episode.durationText!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                )
              else
                const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.textSecondary,
                ),
              if (trailing case final trailing?) ...[
                const SizedBox(width: 4),
                trailing,
              ],
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
