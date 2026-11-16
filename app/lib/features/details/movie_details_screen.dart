import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/form_factor.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/backend/remote_models.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../data/xtream/xtream_models.dart';
import '../downloads/download_button.dart';
import '../player/player_screen.dart';
import '../remote/cast_session.dart';
import '../remote/device_picker.dart';
import 'details_widgets.dart';

class MovieDetailsScreen extends ConsumerWidget {
  const MovieDetailsScreen({super.key, required this.streamId});

  final int streamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(activeSourceProvider).value;
    final api = ref.watch(xtreamApiProvider);
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
            future: api == null
                ? Future.value(const XtreamVodInfo())
                : api
                      .vodInfo(streamId)
                      .catchError((Object _) => const XtreamVodInfo()),
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
                        posterUrl: movie.icon,
                        backdropUrl: info?.backdrop ?? movie.icon,
                        metaLine: [
                          if (movie.rating != null)
                            '★ ${movie.rating!.toStringAsFixed(1)}',
                          if (info?.releaseDate case final d?)
                            d.split('-').first,
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
                        onPlay: () {
                          final containerExtension =
                              info?.containerExtension ??
                              movie.containerExtension;
                          // startPlayback swaps in a completed download.
                          final url = urls.movie(
                            movie,
                            containerExtension: containerExtension,
                          );
                          if (url == null) return;
                          final resume = ref.read(resumeServiceProvider);
                          startPlayback(
                            context,
                            ref,
                            PlayerArgs.single(
                              url: url,
                              title: movie.name,
                              startAt: position == null
                                  ? null
                                  : Duration(seconds: position.positionSecs),
                              identity: PlaybackIdentity(
                                itemType: 'MOVIE',
                                itemId: '$streamId',
                              ),
                              onProgress: (_, pos, dur) => resume?.report(
                                kind: WatchKind.movie,
                                itemId: streamId,
                                title: movie.name,
                                imageUrl: movie.icon,
                                containerExtension: containerExtension,
                                position: pos,
                                duration: dur,
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
          );
        },
      ),
    );
  }
}
