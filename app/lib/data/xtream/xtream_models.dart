import '../discovery/title_identity.dart';
import 'dart:convert';

/// Xtream panels are wildly inconsistent about types: ints arrive as strings,
/// ratings as int/double/string, booleans as 0/1/"1"/true. Every field goes
/// through these helpers instead of direct casts.
String asString(dynamic v, [String fallback = '']) => v?.toString() ?? fallback;

String? asStringOrNull(dynamic v) {
  final s = v?.toString();
  return (s == null || s.isEmpty) ? null : s;
}

int? asInt(dynamic v) => switch (v) {
  final int i => i,
  final num n => n.toInt(),
  final String s => int.tryParse(s.trim()),
  _ => null,
};

double? asDouble(dynamic v) => switch (v) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s.trim()),
  _ => null,
};

bool asBool(dynamic v) => switch (v) {
  final bool b => b,
  final num n => n != 0,
  final String s => s == '1' || s.toLowerCase() == 'true',
  _ => false,
};

DateTime? asEpoch(dynamic v) {
  final seconds = asInt(v);
  if (seconds == null || seconds <= 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
}

class XtreamUserInfo {
  const XtreamUserInfo({
    required this.authenticated,
    required this.status,
    this.expiresAt,
    this.maxConnections,
    this.activeConnections,
    this.isTrial,
    this.createdAt,
    this.outputFormats = const [],
  });

  final bool authenticated;
  final String status;
  final DateTime? expiresAt;
  final int? maxConnections;
  final int? activeConnections;
  final bool? isTrial;
  final DateTime? createdAt;
  final List<String> outputFormats;

  static XtreamUserInfo fromJson(Map<String, dynamic> json) {
    final u = json['user_info'];
    final user = u is Map<String, dynamic> ? u : <String, dynamic>{};
    return XtreamUserInfo(
      authenticated: asBool(user['auth']),
      status: asString(user['status'], 'Unknown'),
      expiresAt: asEpoch(user['exp_date']),
      maxConnections: asInt(user['max_connections']),
      activeConnections: asInt(user['active_cons']),
      isTrial: user['is_trial'] == null ? null : asBool(user['is_trial']),
      createdAt: asEpoch(user['created_at']),
      outputFormats: user['allowed_output_formats'] is List
          ? (user['allowed_output_formats'] as List<dynamic>)
                .whereType<String>()
                .toList()
          : const [],
    );
  }
}

class XtreamCategory {
  const XtreamCategory({required this.id, required this.name});

  final String id;
  final String name;

  static XtreamCategory fromJson(Map<String, dynamic> json) => XtreamCategory(
    id: asString(json['category_id']),
    name: asString(json['category_name'], 'Unnamed'),
  );
}

class XtreamLiveStream {
  const XtreamLiveStream({
    required this.streamId,
    required this.name,
    this.icon,
    this.categoryId,
    this.epgChannelId,
    this.number,
  });

  final int streamId;
  final String name;
  final String? icon;
  final String? categoryId;
  final String? epgChannelId;
  final int? number;

  static XtreamLiveStream? fromJson(Map<String, dynamic> json) {
    final id = asInt(json['stream_id']);
    if (id == null) return null;
    return XtreamLiveStream(
      streamId: id,
      name: asString(json['name'], 'Unnamed'),
      icon: asStringOrNull(json['stream_icon']),
      categoryId: asStringOrNull(json['category_id']),
      epgChannelId: asStringOrNull(json['epg_channel_id']),
      number: asInt(json['num']),
    );
  }
}

class XtreamVodStream {
  const XtreamVodStream({
    required this.streamId,
    required this.name,
    this.icon,
    this.categoryId,
    this.containerExtension,
    this.rating,
    this.ratingScale,
    this.releaseYear,
    this.externalId,
    this.addedAt,
  });

  final int streamId;
  final String name;
  final String? icon;
  final String? categoryId;
  final String? containerExtension;
  final double? rating;
  final int? ratingScale;
  final int? releaseYear;
  final String? externalId;
  final DateTime? addedAt;

  static XtreamVodStream? fromJson(Map<String, dynamic> json) {
    final id = asInt(json['stream_id']);
    if (id == null) return null;
    return XtreamVodStream(
      streamId: id,
      name: asString(json['name'], 'Unnamed'),
      icon: asStringOrNull(json['stream_icon']),
      categoryId: asStringOrNull(json['category_id']),
      containerExtension: asStringOrNull(json['container_extension']),
      externalId: providerExternalId(json),
      releaseYear: titleYear(
        asStringOrNull(json['year']) ??
            asStringOrNull(json['releaseDate']) ??
            asStringOrNull(json['release_date']),
      ),
      ratingScale: asDouble(json['rating_5based']) != null ? 5 : null,
      rating: asDouble(json['rating_5based']) ?? asDouble(json['rating']),
      addedAt: asEpoch(json['added']),
    );
  }
}

class XtreamSeries {
  const XtreamSeries({
    required this.seriesId,
    required this.name,
    this.cover,
    this.categoryId,
    this.plot,
    this.rating,
    this.ratingScale,
    this.releaseYear,
    this.externalId,
    this.lastModifiedAt,
  });

  final int seriesId;
  final String name;
  final String? cover;
  final String? categoryId;
  final String? plot;
  final double? rating;
  final int? ratingScale;
  final int? releaseYear;
  final String? externalId;
  final DateTime? lastModifiedAt;

  static XtreamSeries? fromJson(Map<String, dynamic> json) {
    final id = asInt(json['series_id']);
    if (id == null) return null;
    return XtreamSeries(
      seriesId: id,
      name: asString(json['name'], 'Unnamed'),
      cover: asStringOrNull(json['cover']),
      categoryId: asStringOrNull(json['category_id']),
      plot: asStringOrNull(json['plot']),
      externalId: providerExternalId(json),
      releaseYear: titleYear(
        asStringOrNull(json['year']) ??
            asStringOrNull(json['releaseDate']) ??
            asStringOrNull(json['release_date']),
      ),
      ratingScale: asDouble(json['rating_5based']) != null ? 5 : null,
      rating: asDouble(json['rating_5based']) ?? asDouble(json['rating']),
      lastModifiedAt: asEpoch(json['last_modified']),
    );
  }
}

// Top-level parse functions so they can run in a background isolate via
// compute(); playlists routinely exceed 10k entries.

List<T> _decodeList<T>(String body, T? Function(Map<String, dynamic>) parse) {
  final decoded = jsonDecode(body);
  if (decoded is! List) throw const FormatException('Expected a catalog array');
  final rows = [
    for (final object in decoded.whereType<Map<String, dynamic>>())
      ?parse(object),
  ];
  if (decoded.isNotEmpty && rows.isEmpty) {
    throw const FormatException('Catalog response had no usable entries');
  }
  return rows;
}

List<XtreamCategory> parseCategories(String body) => _decodeList(body, (json) {
  final category = XtreamCategory.fromJson(json);
  return category.id.isEmpty ? null : category;
});

List<XtreamLiveStream> parseLiveStreams(String body) =>
    _decodeList(body, XtreamLiveStream.fromJson);
List<XtreamVodStream> parseVodStreams(String body) =>
    _decodeList(body, XtreamVodStream.fromJson);
List<XtreamSeries> parseSeriesList(String body) =>
    _decodeList(body, XtreamSeries.fromJson);

/// Extra metadata for one movie (`get_vod_info`).
class XtreamVodInfo {
  const XtreamVodInfo({
    this.plot,
    this.genre,
    this.cast,
    this.director,
    this.releaseDate,
    this.externalId,
    this.durationText,
    this.backdrop,
    this.containerExtension,
  });

  final String? plot;
  final String? genre;
  final String? cast;
  final String? director;
  final String? releaseDate;
  final String? externalId;
  final String? durationText;
  final String? backdrop;
  final String? containerExtension;

  static XtreamVodInfo fromJson(Map<String, dynamic> json) {
    final i = json['info'];
    final info = i is Map<String, dynamic> ? i : <String, dynamic>{};
    final m = json['movie_data'];
    final movie = m is Map<String, dynamic> ? m : <String, dynamic>{};
    final backdrops = info['backdrop_path'];
    return XtreamVodInfo(
      plot: asStringOrNull(info['plot']) ?? asStringOrNull(info['description']),
      genre: asStringOrNull(info['genre']),
      cast: asStringOrNull(info['cast']) ?? asStringOrNull(info['actors']),
      director: asStringOrNull(info['director']),
      externalId: providerExternalId(info),
      releaseDate:
          asStringOrNull(info['releasedate']) ??
          asStringOrNull(info['release_date']),
      durationText: asStringOrNull(info['duration']),
      backdrop: backdrops is List && backdrops.isNotEmpty
          ? asStringOrNull(backdrops.first)
          : asStringOrNull(info['movie_image']),
      containerExtension: asStringOrNull(movie['container_extension']),
    );
  }
}

class XtreamEpisode {
  const XtreamEpisode({
    required this.id,
    required this.title,
    required this.season,
    required this.episodeNum,
    this.containerExtension,
    this.plot,
    this.durationText,
    this.image,
  });

  final int id;
  final String title;
  final int season;
  final int episodeNum;
  final String? containerExtension;
  final String? plot;
  final String? durationText;
  final String? image;

  static XtreamEpisode? fromJson(Map<String, dynamic> json) {
    final id = asInt(json['id']);
    if (id == null) return null;
    final i = json['info'];
    final info = i is Map<String, dynamic> ? i : <String, dynamic>{};
    final episodeNum = asInt(json['episode_num']) ?? 0;
    return XtreamEpisode(
      id: id,
      title: asStringOrNull(json['title']) ?? 'Episode $episodeNum',
      season: asInt(json['season']) ?? 0,
      episodeNum: episodeNum,
      containerExtension: asStringOrNull(json['container_extension']),
      plot: asStringOrNull(info['plot']),
      durationText: asStringOrNull(info['duration']),
      image: asStringOrNull(info['movie_image']),
    );
  }
}

/// Series detail (`get_series_info`): metadata plus episodes per season.
class XtreamSeriesInfo {
  const XtreamSeriesInfo({
    this.plot,
    this.genre,
    this.cast,
    this.releaseDate,
    this.externalId,
    required this.seasons,
  });

  final String? plot;
  final String? genre;
  final String? cast;
  final String? releaseDate;
  final String? externalId;

  /// Season number → episodes, sorted; only seasons that have episodes.
  final Map<int, List<XtreamEpisode>> seasons;

  static XtreamSeriesInfo fromJson(Map<String, dynamic> json) {
    final i = json['info'];
    final info = i is Map<String, dynamic> ? i : <String, dynamic>{};

    // `episodes` is a map keyed by season number on most panels, but some
    // return a list of per-season lists.
    final raw = json['episodes'];
    final episodeGroups = switch (raw) {
      final Map<dynamic, dynamic> m => m.values,
      final List<dynamic> l => l,
      _ => const Iterable<dynamic>.empty(),
    };
    final seasons = <int, List<XtreamEpisode>>{};
    for (final group in episodeGroups) {
      if (group is! List) continue;
      for (final e in group.whereType<Map<String, dynamic>>()) {
        final episode = XtreamEpisode.fromJson(e);
        if (episode == null) continue;
        seasons.putIfAbsent(episode.season, () => []).add(episode);
      }
    }
    for (final list in seasons.values) {
      list.sort((a, b) => a.episodeNum.compareTo(b.episodeNum));
    }

    return XtreamSeriesInfo(
      plot: asStringOrNull(info['plot']),
      genre: asStringOrNull(info['genre']),
      cast: asStringOrNull(info['cast']),
      externalId: providerExternalId(info),
      releaseDate:
          asStringOrNull(info['releaseDate']) ??
          asStringOrNull(info['release_date']),
      seasons: seasons,
    );
  }
}

XtreamVodInfo parseVodInfo(String body) {
  final decoded = jsonDecode(body);
  return XtreamVodInfo.fromJson(
    decoded is Map<String, dynamic> ? decoded : <String, dynamic>{},
  );
}

XtreamSeriesInfo parseSeriesInfo(String body) {
  final decoded = jsonDecode(body);
  return XtreamSeriesInfo.fromJson(
    decoded is Map<String, dynamic> ? decoded : <String, dynamic>{},
  );
}
