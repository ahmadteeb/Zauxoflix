import '../../data/discovery/discovery_repository.dart';
import '../../data/discovery/title_identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/form_factor.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/backend/remote_models.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../downloads/download_button.dart';
import 'media_navigation.dart';
import '../remote/device_picker.dart';
import 'details_widgets.dart';

class MovieDetailsScreen extends ConsumerWidget {
  const MovieDetailsScreen({super.key, required this.streamId});

  final int streamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(activeSourceProvider).value;
    final infoFuture = ref.watch(catalogVodInfoProvider(streamId).future);
    final urls = ref.watch(playbackUrlsProvider);
    if (source == null || urls == null) return const SizedBox.shrink();
    final db = ref.watch(databaseProvider);

    return Scaffold(
      body: FutureBuilder(
        future: db.getMovie(source.id, streamId),
        builder: (context, movieSnapshot) {
          final movie = movieSnapshot.data;
          if (movie == null) {
            return movieSnapshot.connectionState == ConnectionState.waiting
                ? const DetailsSkeleton()
                : const Center(child: Text('Movie not found'));
          }
          return FutureBuilder(
            // Detail fetch failing (panel offline) must not block playback,
            // so errors just leave the metadata blank. M3U sources have no
            // info endpoint at all.
            future: infoFuture,
            builder: (context, infoSnapshot) {
              final info = infoSnapshot.data;
              return StreamBuilder(
                stream: db.watchPosition(source.id, WatchKind.movie, streamId),
                builder: (context, positionSnapshot) {
                  final position = positionSnapshot.data;
                  return StreamBuilder(
                    stream: db.watchIsFavorite(
                      source.id,
                      CatalogKind.vod,
                      streamId,
                    ),
                    builder: (context, favSnapshot) {
                      final favorite = favSnapshot.data ?? false;
                      return DetailsScaffold(
                        title: movie.name,
                        discoveryKey: movieKey(
                          movie,
                          year: titleYear(info?.releaseDate),
                          external: info?.externalId,
                        ),
                        providerScore: providerRating(
                          movie.rating,
                          movie.ratingScale,
                        ),
                        posterUrl: movie.icon,
                        backdropUrl: info?.backdrop ?? movie.icon,
                        metaLine: [
                          if ((titleYear(info?.releaseDate) ??
                                  movie.releaseYear)
                              case final year?)
                            '$year',
                          ?info?.durationText,
                          ?info?.genre,
                        ].join('  ·  '),
                        plot: info?.plot,
                        cast: info?.cast,
                        director: info?.director,
                        loadingDetails:
                            infoSnapshot.connectionState ==
                            ConnectionState.waiting,
                        playLabel: position == null ? 'Play' : 'Resume',
                        playProgress:
                            position == null || position.durationSecs <= 0
                            ? null
                            : (position.positionSecs / position.durationSecs)
                                  .clamp(0.0, 1.0),
                        favorite: favorite,
                        onToggleFavorite: () => favorite
                            ? db.removeFavorite(
                                source.id,
                                CatalogKind.vod,
                                streamId,
                              )
                            : db.addFavorite(
                                sourceId: source.id,
                                kind: CatalogKind.vod,
                                itemId: streamId,
                                name: movie.name,
                                imageUrl: movie.icon,
                              ),
                        onCast: kTvBuild
                            ? null
                            : () => castFromDetails(
                                context,
                                ref,
                                identity: PlaybackIdentity(
                                  itemType: 'MOVIE',
                                  itemId: '$streamId',
                                ),
                                positionSec: position?.positionSecs ?? 0,
                              ),
                        extraActions: [
                          if (!kTvBuild)
                            DownloadButton(
                              sourceId: source.id,
                              kind: WatchKind.movie,
                              itemId: streamId,
                              title: movie.name,
                              imageUrl: movie.icon,
                              containerExtension:
                                  info?.containerExtension ??
                                  movie.containerExtension,
                              url: urls.movie(
                                movie,
                                containerExtension:
                                    info?.containerExtension ??
                                    movie.containerExtension,
                              ),
                            ),
                        ],
                        onPlay: () => playMovie(
                          context,
                          ref,
                          movie,
                          position: position,
                          containerExtension: info?.containerExtension,
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
