part of 'live_directory.dart';

enum LiveSportsGroup {
  footballNow('Football on now'),
  bein('beIN SPORTS'),
  alkass('Al Kass'),
  jordan('Roya & Jordan Sport'),
  mbcShahid('MBC & Shahid'),
  saudi('Saudi football'),
  regional('Regional sports'),
  international('International football'),
  other('More sports');

  const LiveSportsGroup(this.label);
  final String label;
}

class LiveSportsSection {
  const LiveSportsSection(this.group, this.stations);
  final LiveSportsGroup group;
  final List<LiveStation> stations;
}

final _sportsEncodedName = RegExp(
  r'sport|alkass|al kass|tha?ma?n|bein (?:extra|news)|shahid|\bssc\b|سبورت|الرياض|الكأس|الكاس|ثمانية|شاهد',
  caseSensitive: false,
);
final _explicitResolution = RegExp(
  r'\b(?:[uf]?hd|sd|[48]k|1080p?|720p?|2160p?)\b',
  caseSensitive: false,
);
final _sportsEncodingTag = RegExp(
  r'\s*\([AFGMQSY∞]\)(?:\s+P$)?(?=\s|$)|\s+\b(?:HDR10\+?|HDR|LOW)(?=\s|$)',
  caseSensitive: false,
);
const _raisedFormatTags = {
  'ᶠʰᵈ': 'FHD',
  'ᵘʰᵈ': 'UHD',
  'ʰᵈ': 'HD',
  'ˢᵈ': 'SD',
  'ʰᵉᵛᶜ': 'HEVC',
};
final _raisedFormat = RegExp(r'(?<=\s)(?:ᶠʰᵈ|ᵘʰᵈ|ʰᵈ|ˢᵈ|ʰᵉᵛᶜ)(?=\s|$)');
final _numberedShahid = RegExp(r'^(?:shahid|شاهد) (?:vip )?\d+$');
final _shahidMatchCategory = RegExp(
  r'(?:مباريات شاهد|شاهد مباريات|shahid matches|shahid sports)',
);
final _providerDivider = RegExp(r'^[\s|\-–—★●✦*]+[★●✦*]');
final _marketPrefix = RegExp(
  r'^(?:VIP\s+)?([A-Z]{2,3})\s*[:|]\s*',
  caseSensitive: false,
);
const _arabMarkets = {
  'AR',
  'ME',
  'JO',
  'JOR',
  'LB',
  'SY',
  'PS',
  'SA',
  'KSA',
  'AE',
  'UAE',
  'QA',
  'KW',
  'OM',
  'BH',
  'EG',
  'IQ',
  'MA',
  'DZ',
  'TN',
  'LY',
  'SD',
  'YE',
};

final _sportWords = RegExp(
  r'(?:^| )(?:sports?|football|soccer|eurosport|motorsport|tennis|golf|racing|nba|nfl|nhl|wwe|الرياضيه|رياضيه|الرياضه|رياضه|سبورت)(?= |$)',
);
final _otherSport = RegExp(
  r'(?:^| )(?:nba|nfl|rugby|cricket|tennis|golf|f 1|formula 1|boxing|racing|wwe'
  r'|basketball|motorsport|nhl|ufc|كره السله|تنس|مصارعه|كريكت|كره اليد)(?= |$)',
);
final _otherFootballCode = RegExp(
  r'(?:american|college|fantasy|australian|gaelic|canadian) football|indian premier league',
);
final _entertainment = RegExp(
  r'(?:^| )(?:cinema|movies?|drama|music|aghani|اغاني|افلام|سينما|دراما|موسيقي)(?= |$)',
);
final _footballTitle = RegExp(
  r'(?:^| )(?:live football|live soccer|football (?:live|match|highlights)|futsal'
  r'|uefa (?:champions|europa|conference|nations|euro|super cup)'
  r'|fifa (?:u \d+ |club |women s )?world cup|afcon|la liga|laliga|bundesliga|serie a'
  r'|copa libertadores|copa america|copa del rey|caf champions league|afc champions league'
  r'|afc asian cup|english premier league|saudi pro league|roshn (?:saudi )?league'
  r'|كره (?:القدم|قدم)|دوري ابطال (?:اوروبا|اسيا|افريقيا)'
  r'|الدوري (?:الانجليزي|الاسباني|الايطالي|السعودي|الاردني) (?:الممتاز|للمحترفين)'
  r'|كاس العالم للانديه)(?= |$)',
);
final _beinNetwork = RegExp(r'^(?:bein|بين) (?:sports?|سبورت|4 k)(?= |$)');
final _alkassNetwork = RegExp(r'^(?:al ?kass|الكاس)(?= |$)');
final _jordanNetwork = RegExp(
  r'^(?:roya sports?|رؤيا (?:سبورت|الرياضيه)|(?:jordan|jrtv) sports?|الاردنيه الرياضيه)(?= |$)',
);
final _mbcShahid = RegExp(r'^(?:mbc|shahid|شاهد)(?= |$)');
final _saudiNetwork = RegExp(
  r'^(?:(?:thamanyah?|thmanyah|ثمانيه) (?:\d+|real|sports?|الرياضيه)|ssc(?: \d+| extra| sport|$)|اس اس سي|(?:ksa|saudi) sports?)(?= |$)',
);
final _regionalNetwork = RegExp(
  r'^(?:(?:abu dhabi|ad|dubai|sharjah|on ?time|on|nile|kuwait|oman|bahrain|iraq(?:iya)?|al iraqiya) sports?|arryadia|الرياضيه المغربيه|العراقيه الرياضيه|ابو ?ظبي الرياضيه|دبي الرياضيه)(?= |$)',
);
final _clubStations = RegExp(
  r'^(?:al ahly tv|zamalek tv|mutv|lfc tv|lfctv|real madrid tv|barca tv|chelsea tv|juventus tv)(?= |$)',
);
final _footballStation = RegExp(
  r'(?:^| )(?:soccer|football|futbol|كرة القدم|كره القدم|uefa|fifa|laliga|la liga|premier league|serie a|bundesliga)(?= |$)',
);
final _digits = RegExp(r'(?:^| )(\d+)(?= |$)');
final _secondaryEdition = RegExp(
  r'(?:^| )(?:xtra|max|extra|news|اخباريه|الاخباريه|en|fr|english|french|real|4 k|2160 p)(?= |$)',
);

LiveSportsGroup? _sportsGroup(LiveStation station, String name, bool foreign) {
  final category = station.genre == LiveGenre.sports;
  final sportName = _sportWords.hasMatch(name);
  if (_otherSport.hasMatch(name) || _otherFootballCode.hasMatch(name)) {
    return LiveSportsGroup.other;
  }
  if (_beinNetwork.hasMatch(name)) {
    return foreign ? LiveSportsGroup.international : LiveSportsGroup.bein;
  }
  if (_alkassNetwork.hasMatch(name)) return LiveSportsGroup.alkass;
  if (_jordanNetwork.hasMatch(name)) return LiveSportsGroup.jordan;
  if (_mbcShahid.hasMatch(name)) {
    if ((category && _numberedShahid.hasMatch(name)) ||
        sportName ||
        name.contains(' ssc ')) {
      return LiveSportsGroup.mbcShahid;
    }
    return null;
  }
  if (_saudiNetwork.hasMatch(name)) return LiveSportsGroup.saudi;
  if (_regionalNetwork.hasMatch(name) ||
      (category &&
          station.regional != null &&
          (station.regional!.market == 'EG' ||
              station.regional!.market == 'AE'))) {
    return LiveSportsGroup.regional;
  }
  if (_footballStation.hasMatch(name) || _clubStations.hasMatch(name)) {
    return LiveSportsGroup.international;
  }
  // The Alwan provider bucket also contains its film, children's and music
  // feeds. Its sports feeds identify themselves by sport or the Sport brand.
  if (name.startsWith('alwan ') && !sportName) return null;
  return (category || sportName) && !_entertainment.hasMatch(name)
      ? LiveSportsGroup.other
      : null;
}

typedef _SportsEntry = ({
  LiveStation station,
  int edition,
  int number,
  String name,
});

/// Built in the same background isolate as the source directory. Guide
/// updates and UI rebuilds never reclassify the complete playlist.
class _LiveSportsIndex {
  _LiveSportsIndex(List<LiveStation> stations) {
    for (final station in stations) {
      if (_providerDivider.hasMatch(station.name)) continue;
      final guideId = station.guideId;
      if (guideId != null) (byGuide[guideId] ??= []).add(station);
      final prefix = _marketPrefix.firstMatch(station.name);
      final foreign =
          prefix != null && !_arabMarkets.contains(prefix[1]!.toUpperCase());
      final split = station.searchKey.indexOf('|');
      final name = prefix == null
          ? (split < 0
                ? station.searchKey
                : station.searchKey.substring(0, split))
          : liveNameKey(station.name.substring(prefix.end));
      final group = _sportsGroup(station, name, foreign);
      if (group == null) continue;
      (groups[group] ??= []).add((
        station: station,
        name: name,
        edition: _secondaryEdition.hasMatch(name) ? 1 : 0,
        number: int.tryParse(_digits.firstMatch(name)?[1] ?? '') ?? 0,
      ));
    }
  }
  final groups = <LiveSportsGroup, List<_SportsEntry>>{};
  final byGuide = <String, List<LiveStation>>{};
}

extension LiveSportsDirectory on LiveDirectory {
  List<LiveSportsSection> sports({
    List<LiveStation> mostWatched = const [],
    Map<String, String> guideLinks = const {},
    Map<String, EpgProgramme> nowPlaying = const {},
    required DateTime now,
  }) {
    final airing = <String, LiveStation>{};
    final footballIds = <String>{};
    final linkedIds = guideLinks.values.toSet();
    for (final item in nowPlaying.entries) {
      final epg = item.value;
      if (!_sports.byGuide.containsKey(item.key) &&
          !linkedIds.contains(item.key)) {
        continue;
      }
      if (epg.startAt.isAfter(now) || !epg.endAt.isAfter(now)) continue;
      final title = catalogQuery(epg.title);
      if (_entertainment.hasMatch(title) ||
          _otherSport.hasMatch(title) ||
          _otherFootballCode.hasMatch(title) ||
          !_footballTitle.hasMatch(title)) {
        continue;
      }
      footballIds.add(item.key);
      for (final station
          in _sports.byGuide[item.key] ?? const <LiveStation>[]) {
        if (epg.sourceId == station.sourceId &&
            (guideLinks[station.key] ?? item.key) == item.key) {
          airing[station.key] = station;
        }
      }
    }
    if (footballIds.isNotEmpty) {
      for (final link in guideLinks.entries) {
        final station = byKey[link.key];
        if (footballIds.contains(link.value) &&
            station != null &&
            station.sourceId == nowPlaying[link.value]?.sourceId &&
            !_providerDivider.hasMatch(station.name)) {
          airing[station.key] = station;
        }
      }
    }
    final order = {
      for (final (i, station) in mostWatched.indexed) station.key: i,
    };
    int watchOrder(LiveStation a, LiveStation b) =>
        (order[a.key] ?? mostWatched.length).compareTo(
          order[b.key] ?? mostWatched.length,
        );
    final football = airing.values.toList()
      ..sort((a, b) {
        final seen = watchOrder(a, b);
        return seen != 0 ? seen : a.key.compareTo(b.key);
      });
    final result = [
      if (football.isNotEmpty)
        LiveSportsSection(LiveSportsGroup.footballNow, football),
    ];
    for (final group in LiveSportsGroup.values) {
      final base = _sports.groups[group];
      if (base == null) continue;
      final entries = base.toList();
      entries.sort((a, b) {
        final seen = watchOrder(a.station, b.station);
        if (seen != 0) return seen;
        final edition = a.edition.compareTo(b.edition);
        if (edition != 0) return edition;
        final number = a.number.compareTo(b.number);
        if (number != 0) return number;
        final name = a.name.compareTo(b.name);
        return name != 0 ? name : a.station.key.compareTo(b.station.key);
      });
      result.add(
        LiveSportsSection(group, [for (final entry in entries) entry.station]),
      );
    }
    return result;
  }
}
