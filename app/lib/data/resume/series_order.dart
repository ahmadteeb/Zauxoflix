import '../xtream/xtream_models.dart';

/// Returns the previous catalog episode, including across season boundaries.
(List<XtreamEpisode>, int)? previousCatalogEpisode(
  XtreamSeriesInfo info,
  int currentId,
) {
  final seasons = info.seasons.keys.toList()..sort();
  (List<XtreamEpisode>, int)? previous;
  for (final season in seasons) {
    final episodes = info.seasons[season]!;
    for (final (i, episode) in episodes.indexed) {
      if (episode.id == currentId) return previous;
      if (season > 0) previous = (episodes, i);
    }
  }
  return null;
}

/// Continues a single-episode or exhausted season queue using catalog order.
(List<XtreamEpisode>, int)? nextCatalogEpisode(
  XtreamSeriesInfo info,
  int currentId, {
  String? lastLabel,
}) {
  final seasons = info.seasons.keys.toList()..sort();
  bool found = false;
  for (final season in seasons) {
    final episodes = info.seasons[season]!;
    for (final (i, episode) in episodes.indexed) {
      if (found && episode.id != currentId && season > 0) return (episodes, i);
      if (episode.id == currentId) found = true;
    }
  }
  if (!found && lastLabel != null) {
    final match = RegExp(r'^S(\d+) E(\d+)\b').firstMatch(lastLabel);
    if (match != null) {
      final lastSeason = int.parse(match[1]!);
      final lastEpisode = int.parse(match[2]!);
      for (final season in seasons.where((n) => n > 0 && n >= lastSeason)) {
        final episodes = info.seasons[season]!;
        final i = episodes.indexWhere(
          (e) => season > lastSeason || e.episodeNum > lastEpisode,
        );
        if (i >= 0) return (episodes, i);
      }
    }
  }
  return null;
}
