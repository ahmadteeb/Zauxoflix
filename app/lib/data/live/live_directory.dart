import '../catalog_search.dart';
import '../db/app_database.dart';
import 'regional_channels.dart';

part 'live_sports.dart';

enum LiveQuality {
  fullHd('1080p'),
  hd('HD'),
  sd('SD'),
  unknown('Original'),
  ultraHd('4K');

  const LiveQuality(this.label);
  final String label;
}

class LiveVariant {
  const LiveVariant(this.stream, this.quality, this.hevc);
  final LiveChannel stream;
  final LiveQuality quality;
  final bool hevc;
}

class LiveStation {
  const LiveStation({
    required this.key,
    required this.name,
    required this.variants,
    required this.searchKey,
    required this.genre,
    required this.regional,
  });

  final String key, name, searchKey;
  final List<LiveVariant> variants;
  final LiveGenre? genre;
  final RegionalChannel? regional;

  LiveChannel get channel => variants.first.stream;
  int get sourceId => channel.sourceId;
  String? get guideId => variants
      .map((v) => v.stream.epgChannelId?.trim().toLowerCase())
      .whereType<String>()
      .firstWhere((id) => id.isNotEmpty, orElse: () => '')
      .nullIfEmpty;
  String? get icon => variants
      .map((v) => v.stream.icon)
      .whereType<String>()
      .firstWhere((url) => url.isNotEmpty, orElse: () => '')
      .nullIfEmpty;

  bool matches(String query, int? number) =>
      searchKey.contains(query) ||
      (number != null && variants.any((v) => v.stream.channelNumber == number));

  bool hasCategory(String id) => variants.any((v) => v.stream.categoryId == id);

  List<LiveVariant> tuneOrder({int? preferred, int? successful}) {
    LiveVariant? find(int? id) =>
        variants.where((version) => version.stream.streamId == id).firstOrNull;
    final first = find(preferred) ?? find(successful);
    return [?first, ...variants.where((v) => !identical(v, first))];
  }
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}

class LiveDirectory {
  LiveDirectory(this.stations)
    : _sports = _LiveSportsIndex(stations),
      byKey = {for (final station in stations) station.key: station},
      byStream = {
        for (final station in stations)
          for (final variant in station.variants)
            variant.stream.streamId: station,
      };

  final List<LiveStation> stations;
  final Map<String, LiveStation> byKey;
  final Map<int, LiveStation> byStream;
  final _LiveSportsIndex _sports;

  List<LiveStation> regional(LiveRegion region) =>
      [
        for (final station in stations)
          if (station.regional case final entry?
              when region.includes(entry.market))
            station,
      ]..sort(
        (a, b) => _editorial[a.regional!.key]!.compareTo(
          _editorial[b.regional!.key]!,
        ),
      );
}

String liveNameKey(String value) =>
    catalogQuery(value.replaceAll('+', ' plus '));

final _editorial = {
  for (final (i, channel) in regionalChannels.indexed) channel.key: i,
};
final _aliases = {
  for (final entry in regionalChannels)
    for (final alias in [entry.name, ...entry.aliases])
      liveNameKey(alias): entry,
};
final _prefix = RegExp(
  r'^\s*\[?(AR|JO|JOR|LB|SY|PS|SA|KSA|AE|UAE|QA|KW|OM|BH|EG|IQ)\]?\s*[:|–-]\s*',
  caseSensitive: false,
);
final _format = RegExp(
  r'(^|[\s._|\-\[(])(?:(4k|uhd|2160p?|fhd|1080p?|hd|720p?|sd|576p?|480p?)|(hevc|h\.?26[45]))[\s\])]*$',
  caseSensitive: false,
);

typedef _Parsed = ({
  String name,
  LiveVariant variant,
  RegionalChannel? regional,
});

_Parsed _parse(LiveChannel stream) {
  var name = stream.name.trim();
  final tag = _prefix.firstMatch(name);
  if (tag != null) name = name.substring(tag.end);
  final unqualified = name;
  // Some sports lineups append a server letter on either side of the
  // resolution, e.g. "Alkass 1 HD (M)" and "Bein Sport 1 (G) 4K".
  if (_sportsEncodedName.hasMatch(name)) {
    name = name.replaceAllMapped(
      _raisedFormat,
      (tag) => _raisedFormatTags[tag[0]!]!,
    );
    if (_explicitResolution.hasMatch(name)) {
      name = name.replaceAll(_sportsEncodingTag, ' ').trim();
    }
  }
  var hevc = false;
  var quality = LiveQuality.unknown;
  var match = _format.firstMatch(name);
  while (match != null) {
    // Some stations have a format token in their official brand (beIN 4K).
    if (_aliases.containsKey(liveNameKey(name))) {
      if (match[2]?.toLowerCase() == '4k') quality = LiveQuality.ultraHd;
      break;
    }
    final resolution = match[2]?.toLowerCase();
    if (resolution != null && quality == LiveQuality.unknown) {
      quality = switch (resolution) {
        '4k' || 'uhd' || '2160' || '2160p' => LiveQuality.ultraHd,
        'fhd' || '1080' || '1080p' => LiveQuality.fullHd,
        'hd' || '720' || '720p' => LiveQuality.hd,
        _ => LiveQuality.sd,
      };
    }
    hevc |=
        match[3]?.replaceAll('.', '').toLowerCase() == 'h265' ||
        match[3]?.toLowerCase() == 'hevc';
    name = name.substring(0, match.start).trimRight();
    match = _format.firstMatch(name);
  }
  if (name.isEmpty) name = unqualified.isEmpty ? stream.name : unqualified;
  final entry = _aliases[liveNameKey(name)];
  final market = switch (tag?[1]?.toUpperCase()) {
    'JOR' => 'JO',
    'KSA' => 'SA',
    'UAE' => 'AE',
    final code => code,
  };
  final compatible =
      market == null || market == 'AR' || entry?.market == market;
  if (!compatible && tag != null) {
    name = stream.name.substring(0, tag.end) + name;
  }
  return (
    name: name,
    variant: LiveVariant(stream, quality, hevc),
    regional: compatible ? entry : null,
  );
}

LiveGenre? _categoryGenre(String name) {
  final key = ' ${catalogQuery(name)} ';
  bool has(List<String> words) =>
      words.any((word) => key.contains(' ${catalogQuery(word)} '));
  if (has([
        'sport',
        'sports',
        'football',
        'soccer',
        'الرياضية',
        'رياضية',
        'رياضة',
        'كرة القدم',
      ]) ||
      _shahidMatchCategory.hasMatch(key)) {
    return LiveGenre.sports;
  }
  if (has(['news', 'أخبار', 'اخبارية'])) return LiveGenre.news;
  if (has(['kids', 'children', 'أطفال'])) return LiveGenre.kids;
  if (has(['documentary', 'documentaries', 'وثائقية'])) {
    return LiveGenre.factual;
  }
  if (has(['entertainment', 'drama', 'cinema', 'ترفيه', 'دراما'])) {
    return LiveGenre.entertainment;
  }
  return null;
}

/// Build from one committed source snapshot. EPG IDs can disambiguate a feed,
/// but a shared ID alone never joins two differently named stations.
LiveDirectory buildLiveDirectory(
  List<LiveChannel> rows,
  List<Category> categories,
) {
  final genres = {
    for (final category in categories)
      category.categoryId: _categoryGenre(category.name),
  };
  final buckets = <String, List<_Parsed>>{};
  for (final row in rows) {
    final parsed = _parse(row);
    final parsedKey = liveNameKey(parsed.name);
    // A numbered Shahid event feed can share a name with a general feed.
    final event =
        genres[row.categoryId] == LiveGenre.sports &&
        _numberedShahid.hasMatch(parsedKey);
    final base =
        parsed.regional?.key ?? 'local:$parsedKey${event ? '|sports' : ''}';
    (buckets[base] ??= []).add(parsed);
  }
  final stations = <LiveStation>[];
  for (final bucket in buckets.entries) {
    final candidates = bucket.value;
    final ids = {
      for (final item in candidates)
        if (item.variant.stream.epgChannelId?.trim().toLowerCase().nullIfEmpty
            case final String id)
          id,
    };
    final hasEvidence =
        candidates.first.regional != null ||
        ids.isNotEmpty ||
        candidates.any(
          (item) =>
              item.variant.quality != LiveQuality.unknown || item.variant.hevc,
        );
    final groups = <String, List<_Parsed>>{};
    for (final candidate in candidates) {
      final id = candidate.variant.stream.epgChannelId
          ?.trim()
          .toLowerCase()
          .nullIfEmpty;
      final distinct =
          candidates.length > 1 &&
          (!hasEvidence || (ids.length > 1 && id == null));
      final suffix = distinct
          ? '|stream:${candidate.variant.stream.streamId}'
          : ids.length > 1
          ? '|guide:${id!}'
          : '';
      (groups[bucket.key + suffix] ??= []).add(candidate);
    }
    for (final group in groups.entries) {
      final first = group.value.first;
      final regional = first.regional;
      final name = regional?.name ?? first.name;
      final versions = group.value.map((p) => p.variant).toList()
        ..sort((a, b) {
          final quality = a.quality.index.compareTo(b.quality.index);
          return quality != 0
              ? quality
              : a.stream.streamId.compareTo(b.stream.streamId);
        });
      stations.add(
        LiveStation(
          key: group.key,
          name: name,
          variants: List.unmodifiable(versions),
          searchKey: [
            catalogQuery(name),
            for (final alias in regional?.aliases ?? const <String>[])
              catalogQuery(alias),
            for (final variant in versions) catalogQuery(variant.stream.name),
          ].join('|'),
          genre: regional?.genre ?? genres[first.variant.stream.categoryId],
          regional: regional,
        ),
      );
    }
  }
  return LiveDirectory(List.unmodifiable(stations));
}

Map<String, String> matchLiveGuide(
  LiveDirectory directory,
  Map<String, List<String>> displayNames,
) {
  final idsByName = <String, Set<String>>{};
  for (final entry in displayNames.entries) {
    for (final name in entry.value) {
      (idsByName[liveNameKey(name)] ??= {}).add(entry.key);
    }
  }
  final matches = <String, String>{};
  for (final station in directory.stations) {
    if (station.guideId case final String id
        when displayNames.containsKey(id)) {
      matches[station.key] = id;
      continue;
    }
    final matchesForName = {
      for (final name in [station.name, ...?station.regional?.aliases])
        ...?idsByName[liveNameKey(name)],
    };
    if (matchesForName.length == 1) {
      matches[station.key] = matchesForName.single;
    }
  }
  return matches;
}
