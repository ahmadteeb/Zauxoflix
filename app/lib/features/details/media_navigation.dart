import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/media_item.dart';
import '../../data/backend/remote_models.dart';
import '../../data/db/app_database.dart';
import '../../data/live/live_providers.dart';
import '../../data/providers.dart';
import '../live/live_playback.dart';
import '../../data/xtream/xtream_models.dart';
import '../player/player_screen.dart';
import '../remote/cast_session.dart';

/// Live channels play immediately; movies and series open their details.
void openMediaItem(BuildContext context, WidgetRef ref, MediaItem item) {
  final id = item.id;
  if (id == null) return;
  switch (item.type) {
    case MediaType.live:
      _playLive(context, ref, id, item);
    case MediaType.movie:
      context.push('/movie/$id');
    case MediaType.series:
      context.push('/series/$id');
    case null:
      break;
  }
}

/// Keeps playback, offline downloads, casting and progress consistent across entry points.
Future<void> playMovie(
  BuildContext context,
  WidgetRef ref,
  Movie movie, {
  PlaybackPosition? position,
  String? containerExtension,
}) async {
  final urls = ref.read(playbackUrlsProvider);
  final resume = ref.read(resumeServiceProvider);
  if (ref.read(activeSourceProvider).value?.id != movie.sourceId ||
      urls == null) {
    return;
  }
  final extension =
      containerExtension ??
      position?.containerExtension ??
      movie.containerExtension;
  final url = urls.movie(movie, containerExtension: extension);
  if (url == null) return;
  await startPlayback(
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
        itemId: '${movie.streamId}',
      ),
      onProgress: (_, pos, dur) => resume?.report(
        kind: WatchKind.movie,
        itemId: movie.streamId,
        title: movie.name,
        imageUrl: movie.icon,
        containerExtension: extension,
        position: pos,
        duration: dur,
      ),
    ),
  );
}

/// Plays a Continue Watching entry directly from its stored metadata,
/// re-reporting progress under the same key.
Future<void> playResumable(
  BuildContext context,
  WidgetRef ref,
  PlaybackPosition position,
) async {
  final source = ref.read(activeSourceProvider).value;
  final urls = ref.read(playbackUrlsProvider);
  final resume = ref.read(resumeServiceProvider);
  if (source == null || urls == null) return;

  // An episode resumes inside its season's playlist so the player's
  // next/previous controls walk the series. Any lookup failure (or a
  // non-Xtream source) falls through to single-item playback below.
  if (position.kind == WatchKind.episode && position.seriesId != null) {
    final args = await _episodePlaylist(ref, position);
    if (args != null) {
      if (!context.mounted) return;
      await startPlayback(context, ref, args);
      return;
    }
  }

  final url = switch (position.kind) {
    WatchKind.movie =>
      await ref
          .read(databaseProvider)
          .getMovie(source.id, position.itemId)
          .then(
            (movie) => movie == null
                ? null
                : urls.movie(
                    movie,
                    containerExtension: position.containerExtension,
                  ),
          ),
    WatchKind.episode => urls.episode(
      position.itemId,
      position.containerExtension,
    ),
  };
  if (url == null || !context.mounted) return;

  await startPlayback(
    context,
    ref,
    PlayerArgs.single(
      url: url,
      title: position.title,
      subtitle: position.subtitle,
      startAt: Duration(seconds: position.positionSecs),
      identity: switch (position.kind) {
        WatchKind.movie => PlaybackIdentity(
          itemType: 'MOVIE',
          itemId: '${position.itemId}',
        ),
        WatchKind.episode when position.seriesId != null => PlaybackIdentity(
          itemType: 'SERIES',
          itemId: '${position.seriesId}',
          episodeId: '${position.itemId}',
        ),
        WatchKind.episode => null,
      },
      onProgress: (_, pos, dur) => resume?.report(
        kind: position.kind,
        itemId: position.itemId,
        seriesId: position.seriesId,
        title: position.title,
        subtitle: position.subtitle,
        imageUrl: position.imageUrl,
        containerExtension: position.containerExtension,
        position: pos,
        duration: dur,
      ),
    ),
  );
}

/// Builds a whole-season playlist positioned on the episode being resumed, so
/// the player can advance to the next/previous episode. Returns null when the
/// source isn't Xtream, the series info can't be fetched, or the episode isn't
/// found — callers then fall back to single-item playback.
Future<PlayerArgs?> _episodePlaylist(
  WidgetRef ref,
  PlaybackPosition position,
) async {
  final api = ref.read(xtreamApiProvider);
  final resume = ref.read(resumeServiceProvider);
  if (api == null) return null;
  final seriesId = position.seriesId!;

  final info = await api
      .seriesInfo(seriesId)
      .then<Object?>((v) => v, onError: (Object _) => null);
  if (info is! XtreamSeriesInfo) return null;

  for (final episodes in info.seasons.values) {
    final index = episodes.indexWhere((e) => e.id == position.itemId);
    if (index == -1) continue;
    return PlayerArgs(
      items: [
        for (final (i, e) in episodes.indexed)
          PlayerItem(
            url: api.seriesEpisodeUrl(e.id, e.containerExtension),
            title: position.title,
            episodeImage: e.image,
            seriesCover: position.imageUrl,
            containerExtension: e.containerExtension,
            subtitle: 'S${e.season} E${e.episodeNum} — ${e.title}',
            startAt: i == index
                ? Duration(seconds: position.positionSecs)
                : null,
            identity: PlaybackIdentity(
              itemType: 'SERIES',
              itemId: '$seriesId',
              episodeId: '${e.id}',
            ),
          ),
      ],
      initialIndex: index,
      onProgress: (i, pos, dur) {
        final e = episodes[i];
        resume?.report(
          kind: WatchKind.episode,
          itemId: e.id,
          seriesId: seriesId,
          title: position.title,
          subtitle: 'S${e.season} E${e.episodeNum} — ${e.title}',
          imageUrl: position.imageUrl,
          containerExtension: e.containerExtension,
          position: pos,
          duration: dur,
        );
      },
    );
  }
  return null;
}

Future<void> _playLive(
  BuildContext context,
  WidgetRef ref,
  int id,
  MediaItem item,
) async {
  final source = ref.read(activeSourceProvider).value;
  final urls = ref.read(playbackUrlsProvider);
  if (source == null || urls == null) return;
  final directory = ref.read(liveDirectoryProvider(source.id)).value;
  final station = directory?.byStream[id];
  if (station != null && directory != null) {
    final args = livePlayerQueue(
      directory.stations,
      station,
      urls,
      ref.read(liveTuningProvider(source.id)).value ?? const {},
    );
    if (args != null) {
      await startPlayback(context, ref, args);
      return;
    }
  }
  final channel = await ref
      .read(databaseProvider)
      .getLiveChannel(source.id, id);
  final url = channel == null ? null : urls.live(channel);
  if (url == null || !context.mounted) return;
  await startPlayback(
    context,
    ref,
    PlayerArgs.single(
      url: url,
      title: item.title,
      subtitle: item.subtitle,
      live: true,
      liveLogo: channel?.icon ?? item.imageUrl,
      identity: PlaybackIdentity(itemType: 'LIVE', itemId: '$id'),
    ),
  );
}
