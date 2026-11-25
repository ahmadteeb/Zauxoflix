import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/backend/remote_models.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../data/resume/resume_service.dart';
import '../../data/xtream/xtream_api.dart';
import '../../data/xtream/xtream_models.dart';
import 'player_screen.dart';

export 'player_live_info.dart';

final playerSeriesProvider = FutureProvider.autoDispose
    .family<XtreamSeriesInfo, int>((ref, id) {
      final api = ref.watch(xtreamApiProvider);
      if (api == null) return const XtreamSeriesInfo(seasons: {});
      return api.seriesInfo(id);
    });

PlayerArgs seasonPlayback(
  XtreamApi api,
  SeriesItem series,
  List<XtreamEpisode> episodes,
  int index,
  ResumeService? resume, {
  PlaybackPosition? position,
}) {
  return PlayerArgs(
    items: [
      for (final (i, e) in episodes.indexed)
        PlayerItem(
          url: api.seriesEpisodeUrl(e.id, e.containerExtension),
          title: series.name,
          episodeImage: e.image,
          seriesCover: series.cover,
          containerExtension: e.containerExtension,
          subtitle: 'S${e.season} E${e.episodeNum} — ${e.title}',
          startAt: i == index && position != null
              ? Duration(seconds: position.positionSecs)
              : null,
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
  );
}

class PlayerSynopsis extends ConsumerWidget {
  const PlayerSynopsis({super.key, required this.item});
  final PlayerItem item;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(item.identity?.itemId ?? '');
    if (id == null) return const SizedBox.shrink();
    String? details;
    if (item.identity?.itemType == 'MOVIE') {
      final info = ref.watch(catalogVodInfoProvider(id)).value;
      details = [
        if (info?.releaseDate case final date? when date.length >= 4)
          date.substring(0, 4),
        ?info?.durationText,
        ?info?.plot,
      ].join('  ·  ');
    } else if (item.identity?.itemType == 'SERIES') {
      final info = ref.watch(playerSeriesProvider(id)).value;
      details = info?.seasons.values
          .expand((s) => s)
          .where((e) => e.id.toString() == item.identity?.episodeId)
          .firstOrNull
          ?.plot;
    }
    if (details == null || details.isEmpty) return const SizedBox.shrink();
    return Text(
      details,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: Colors.white70),
    );
  }
}
