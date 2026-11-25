import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/live/live_directory.dart';

LiveChannel feed(int id, String name, {String? guide, String? category}) =>
    LiveChannel(
      sourceId: 1,
      streamId: id,
      name: name,
      searchName: name,
      epgChannelId: guide,
      categoryId: category,
    );
Category category(String id, String name) =>
    Category(sourceId: 1, kind: CatalogKind.live, categoryId: id, name: name);

void main() {
  final now = DateTime.utc(2026, 11, 25, 12);
  EpgProgramme programme(
    String id,
    String title, {
    int source = 1,
    bool ended = false,
  }) => EpgProgramme(
    sourceId: source,
    channelId: id,
    title: title,
    startAt: now.subtract(const Duration(hours: 1)),
    endAt: ended ? now : now.add(const Duration(minutes: 30)),
  );

  test(
    'recognizes local football families, preserves editions and combines formats',
    () {
      final directory = buildLiveDirectory(
        [
          feed(1, 'Bein Sport 1 (G) 4k'),
          feed(2, 'Bein Sport 1 (M) SD LOW'),
          feed(3, 'بي ان سبورت ١'),
          feed(4, 'FR: beIN Sports 1 FHD'),
          feed(5, 'Alkass 1 HD (M)'),
          feed(6, 'الكأس ١'),
          feed(7, 'THAMANYA 1 FHD HDR (∞)'),
          feed(8, 'ثمانية ١'),
          feed(9, 'AD SPORT 1 4K (∞)'),
          feed(10, 'ON Time Sports 1 FHD (M)'),
          feed(11, 'رؤيا سبورت ١'),
          feed(12, 'Shahid Sports 2'),
          feed(13, 'MBC Pro Sports 1'),
          feed(14, 'beIN Sports NBA'),
          feed(15, 'Roya TV'),
          feed(16, 'MBC 2'),
          feed(17, 'Shahid VIP Drama'),
          feed(18, 'beIN Movies 1'),
          feed(19, '--●★| OPTUS SPORT |★●--'),
          feed(20, 'Kassala TV'),
          feed(21, 'Sky Sports Football'),
          feed(22, 'AlKass 1 ʰᵈ'),
          feed(23, 'THAMANYA 1 FHD (∞) P'),
          feed(24, 'KSA SPORTS 1 ʰᵉᵛᶜ'),
          feed(25, 'KSA SPORTS 1 FHD'),
          feed(26, 'beIN Extra 1 (M) FHD'),
          feed(27, 'Bein News 4k'),
          feed(28, 'beIN SPORTS Xtra 1'),
          feed(29, 'Alwan Aghani', category: 'sport'),
        ],
        [category('sport', 'Sports')],
      );
      final sections = directory.sports(now: now);
      final byGroup = {
        for (final section in sections) section.group: section.stations,
      };
      expect(byGroup.keys, [
        LiveSportsGroup.bein,
        LiveSportsGroup.alkass,
        LiveSportsGroup.jordan,
        LiveSportsGroup.mbcShahid,
        LiveSportsGroup.saudi,
        LiveSportsGroup.regional,
        LiveSportsGroup.international,
        LiveSportsGroup.other,
      ]);
      expect(
        byGroup[LiveSportsGroup.bein]!.map((s) => s.name),
        containsAll([
          'beIN Sports 1',
          'beIN Sports Xtra 1',
          'beIN Sports News',
        ]),
      );
      expect(directory.byStream[1], same(directory.byStream[3]));
      expect(directory.byStream[3]!.variants, hasLength(3));
      expect(directory.byStream[5], same(directory.byStream[6]));
      expect(directory.byStream[5], same(directory.byStream[22]));
      expect(directory.byStream[7], same(directory.byStream[8]));
      expect(directory.byStream[7], same(directory.byStream[23]));
      expect(directory.byStream[24], same(directory.byStream[25]));
      expect(directory.byStream[26], same(directory.byStream[28]));
      expect(
        byGroup[LiveSportsGroup.international],
        contains(directory.byStream[4]),
      );
      expect(byGroup[LiveSportsGroup.jordan]!.single.name, 'Roya Sports 1');
      expect(byGroup[LiveSportsGroup.other]!.single.name, 'beIN Sports NBA');
      final ids = sections
          .expand((s) => s.stations)
          .expand((s) => s.variants)
          .map((v) => v.stream.streamId)
          .toSet();
      expect(ids.intersection({15, 16, 17, 18, 19, 20, 29}), isEmpty);
    },
  );

  test(
    'only numbered Shahid feeds in the sports bucket join the sports family',
    () {
      final dir = buildLiveDirectory(
        [
          feed(1, 'Shahid 1 FHD', category: 'events'),
          feed(2, 'Shahid 1 HD', category: 'events'),
          feed(3, 'Shahid 1 HD', category: 'general'),
          feed(4, 'SHAHID VIP | ACTiON 1', category: 'general'),
        ],
        [
          category('general', 'SHAHID - شاهد'),
          category('events', 'Shahid Events - مباريات شاهد'),
        ],
      );
      final events = dir.sports(now: now).single;
      expect(events.group, LiveSportsGroup.mbcShahid);
      expect(events.stations.single.variants.map((v) => v.stream.streamId), [
        1,
        2,
      ]);
      expect(dir.byStream[3], isNot(same(dir.byStream[1])));
    },
  );

  test(
    'current football follows guide links, source and time; broadcaster stays browsable',
    () {
      final dir = buildLiveDirectory([
        feed(1, 'MBC Action', guide: 'mbc'),
        feed(2, 'beIN Sports 1', guide: 'old'),
        feed(3, 'Roya TV', guide: 'roya'),
        feed(4, 'Shahid', guide: 'stale'),
        feed(5, 'MBC Masr', guide: 'movie'),
        feed(6, 'Roya Kids', guide: 'nfl'),
        feed(7, 'MBC Drama', guide: 'different-source'),
      ], []);
      final guide = {
        'mbc': programme(
          'mbc',
          'UEFA Champions League · Arsenal v Real Madrid',
        ),
        'new': programme('new', 'دوري أبطال آسيا'),
        'roya': programme('roya', 'NFL Sunday Night Football'),
        'stale': programme('stale', 'FIFA World Cup', ended: true),
        'movie': programme('movie', 'FIFA Uncovered'),
        'nfl': programme('nfl', 'American Football'),
        'different-source': programme(
          'different-source',
          'English Premier League',
          source: 2,
        ),
      };
      final sections = dir.sports(
        now: now,
        nowPlaying: guide,
        guideLinks: {dir.byStream[2]!.key: 'new'},
      );
      expect(sections.first.group, LiveSportsGroup.footballNow);
      expect(
        sections.first.stations,
        unorderedEquals([dir.byStream[1], dir.byStream[2]]),
      );
      expect(sections.last.group, LiveSportsGroup.bein);
      expect(sections.last.stations.single, dir.byStream[2]);
      final later = dir.sports(
        now: now.add(const Duration(minutes: 31)),
        nowPlaying: guide,
      );
      expect(later.single.group, LiveSportsGroup.bein);
    },
  );

  test(
    'watch history leads each family, numbered feeds sort naturally without history',
    () {
      final rows = [
        feed(1, 'Al Kass 10'),
        feed(2, 'Al Kass 2'),
        feed(3, 'Al Kass 1'),
      ];
      final dir = buildLiveDirectory(rows, []);
      expect(dir.sports(now: now).single.stations.map((s) => s.name), [
        'Alkass 1',
        'Alkass 2',
        'Alkass 10',
      ]);
      expect(
        dir
            .sports(now: now, mostWatched: [dir.byStream[1]!])
            .single
            .stations
            .map((s) => s.name),
        ['Alkass 10', 'Alkass 1', 'Alkass 2'],
      );
      expect(
        buildLiveDirectory([feed(1, 'Roya TV')], []).sports(now: now),
        isEmpty,
      );
    },
  );

  test(
    'numbered services precede special editions until viewing changes the order',
    () {
      final dir = buildLiveDirectory(
        [
          feed(1, 'Bein Sport Real 4k [3840×2160p]'),
          feed(2, 'beIN Sports 4'),
          feed(3, 'THAMANYA Real 4k'),
          feed(4, 'Thmanyah 1'),
          feed(5, 'Alwan Korea', category: 'mixed'),
          feed(6, 'Alwan F1', category: 'mixed'),
        ],
        [category('mixed', 'Alwan Sport - ألوان سبورت')],
      );
      final sections = dir.sports(now: now);
      expect(sections[0].stations, [dir.byStream[2], dir.byStream[1]]);
      expect(sections[1].stations, [dir.byStream[4], dir.byStream[3]]);
      expect(sections.last.stations, [dir.byStream[6]]);
      expect(
        dir
            .sports(now: now, mostWatched: [dir.byStream[1]!])
            .first
            .stations
            .first,
        same(dir.byStream[1]),
      );
    },
  );
}
