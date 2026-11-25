import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/epg/xmltv_parser.dart';
import 'package:zauxoflix/data/live/live_directory.dart';
import 'package:zauxoflix/data/live/live_providers.dart';
import 'package:zauxoflix/data/live/regional_channels.dart';
import 'package:zauxoflix/data/providers.dart';
import 'package:zauxoflix/features/live/live_playback.dart';
import 'package:zauxoflix/features/live/live_watch_tracker.dart';

LiveChannel feed(int id, String name, [String? guide]) => LiveChannel(
  sourceId: 1,
  streamId: id,
  name: name,
  searchName: name,
  epgChannelId: guide,
  streamUrl: 'https://example.invalid/$id',
);

void main() {
  test('groups feed quality and aliases while retaining separate editions', () {
    final directory = buildLiveDirectory([
      feed(1, 'JO | ROYA HD'),
      feed(2, 'AR: Roya TV FHD HEVC'),
      feed(3, 'رؤيا 4K'),
      feed(4, 'Roya Kitchen HD'),
      feed(5, 'Roya Kitchen 2 HD'),
      feed(6, 'MBC Masr HD'),
      feed(7, 'MBC Masr 2 HD'),
      feed(8, 'AR: MBC MASR USA FHD'),
      feed(9, 'beIN Sports 1 HD', 'beinsports'),
      feed(10, 'beIN Sports 2 HD', 'beinsports'),
      feed(11, 'beIN Sports EN 1 HD', 'beinsports'),
      feed(12, 'MBC Masr +1 HD'),
      feed(13, 'Unlabeled'),
      feed(14, 'Unlabeled'),
      feed(15, 'New station HD', 'east'),
      feed(16, 'New station FHD', 'west'),
      feed(17, 'New station SD'),
    ], []);
    final roya = directory.byStream[1]!;
    expect(roya, same(directory.byStream[2]));
    expect(roya, same(directory.byStream[3]));
    expect(roya.variants.map((v) => v.stream.streamId), [2, 1, 3]);
    expect(roya.matches('رؤيا', null), isTrue);
    expect(
      roya.tuneOrder(preferred: 99, successful: 1).first.stream.streamId,
      1,
    );
    expect(directory.stations, hasLength(15));
    expect(directory.regional(LiveRegion.jordan), contains(roya));
    expect(directory.regional(LiveRegion.egypt).map((s) => s.name), [
      'MBC Masr',
      'MBC Masr 2',
    ]);
    expect(directory.byStream[5]!.regional, isNull);
    expect(directory.byStream[8]!.regional, isNull);
  });

  test('queues distinct stations with a single automatic fallback', () {
    final directory = buildLiveDirectory([
      feed(
        1,
        'Roya HD',
      ).copyWith(icon: const Value('https://example.invalid/roya.png')),
      feed(2, 'Roya FHD'),
      feed(3, 'Roya 4K'),
      feed(4, 'Al Mamlaka HD'),
    ], []);
    final roya = directory.byStream[1]!;
    final args = livePlayerQueue(
      directory.stations,
      roya,
      const PlaybackUrls(null),
      {},
    )!;
    expect(args.items, hasLength(2));
    expect(args.items.first.identity!.itemId, '2');
    expect(args.items.first.liveAlternate!.identity!.itemId, '1');
    expect(args.items.first.liveLogo, 'https://example.invalid/roya.png');
    expect(args.items.first.liveAlternate!.liveLogo, args.items.first.liveLogo);
    expect(args.items.last.liveLogo, isNull);
    expect(args.items.first.liveAlternate!.liveAlternate, isNull);
    final pinned = stationPlayerItem(
      roya,
      const PlaybackUrls(null),
      null,
      choice: const LiveVersionChoice(3),
    )!;
    expect(pinned.liveVersion, '4K');
    expect(pinned.liveAlternate, isNull);
  });

  test(
    'reads real XMLTV aliases and requires unambiguous guide names',
    () async {
      final dir = await Directory.systemTemp.createTemp('zauxoflix_guide_test');
      addTearDown(() => dir.delete(recursive: true));
      final file = await File('${dir.path}/tv.xml').writeAsString('''
<tv>
  <channel id=" JO-ROYA "><display-name lang="ar">رؤيا</display-name><display-name>Roya &amp; Family</display-name></channel>
  <channel id="one"><display-name>beIN Sports 1</display-name></channel>
  <channel id="two"><display-name>beIN Sports 1</display-name></channel>
  <programme channel="jo-roya" start="20241125180000 +0300" stop="20241125190000 +0300"><title>News</title></programme>
</tv>
''');
      final names = await readXmltvChannelNames(file.path);
      final directory = buildLiveDirectory([
        feed(1, 'JO | Roya FHD'),
        feed(2, 'beIN Sports 1 HD'),
      ], []);
      expect(names['jo-roya'], ['رؤيا', 'Roya & Family']);
      expect(matchLiveGuide(directory, names), {
        directory.byStream[1]!.key: 'jo-roya',
      });
    },
  );

  test('qualification excludes pauses and never reports time twice', () {
    final clock = LiveWatchTime();
    const start = Duration(seconds: 10);
    clock.setPlaying(true, start);
    clock.setPlaying(false, const Duration(seconds: 26));
    expect(clock.takeQualifiedSeconds(const Duration(seconds: 50)), 0);
    clock.setPlaying(true, const Duration(seconds: 50));
    expect(clock.takeQualifiedSeconds(const Duration(seconds: 64)), 30);
    expect(clock.takeQualifiedSeconds(const Duration(seconds: 66)), 2);
  });

  test(
    'live viewing accumulates per source and profile and ranks grouped variants',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db.insertSource(
        SourcesCompanion.insert(
          name: 'Test',
          serverUrl: '',
          username: '',
          password: '',
        ),
      );
      await db.replaceLiveChannels(1, [
        for (final (id, name) in [
          (1, 'Roya HD'),
          (2, 'Roya FHD'),
          (3, 'Al Mamlaka HD'),
        ])
          LiveChannelsCompanion.insert(sourceId: 1, streamId: id, name: name),
      ]);
      final directory = buildLiveDirectory(
        await db.watchLiveChannels(1, limit: null).first,
        [],
      );
      final now = DateTime(2026, 11, 25, 10);
      await db.addLiveViewing(1, 'a', 1, now, 30);
      await db.addLiveViewing(1, 'a', 1, now, 10);
      await db.addLiveViewing(1, 'a', 2, now, 35);
      await db.addLiveViewing(
        1,
        'a',
        3,
        now.subtract(const Duration(days: 29)),
        60,
      );
      await db.addLiveViewing(
        1,
        'a',
        3,
        now.subtract(const Duration(days: 30)),
        100,
      );
      await db.addLiveViewing(1, 'b', 3, now, 200);
      final ranked = rankLiveStations(
        directory: directory,
        region: LiveRegion.jordan,
        history: await db.watchLiveViewing(1, 'a').first,
        favorites: const [],
        recent: const [],
        now: now,
      );
      expect(ranked.mostWatched.map((s) => s.name), ['Roya TV', 'Al Mamlaka']);
      expect(ranked.minutes[directory.byStream[1]!.key], 1);

      final key = directory.byStream[1]!.key;
      await db.saveLiveTuning(1, 'a', key, preferred: const Value(2));
      await db.saveLiveTuning(1, 'a', key, successful: const Value(1));
      final saved = (await db.watchLiveTuning(1, 'a').first).single;
      expect(saved.preferredStream, 2);
      expect(saved.successfulStream, 1);
      expect(await db.watchLiveTuning(1, 'b').first, isEmpty);

      await db.saveLiveGuideLink(1, key, 'selected');
      await db.replaceAutomaticGuideLinks(1, {key: 'auto'});
      expect((await db.liveGuideLinksFor(1)).single.guideId, 'selected');
    },
  );
}
