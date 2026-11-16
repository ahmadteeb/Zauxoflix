import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/data/m3u/m3u_parser.dart';

void main() {
  test('parses a standard playlist with attributes', () async {
    const playlist = '''
#EXTM3U url-tvg="http://example.com/epg.xml"
#EXTINF:-1 tvg-id="BBC1.uk" tvg-logo="http://logo/bbc1.png" group-title="UK" tvg-chno="1",BBC One
http://server/live/user/pass/1.ts
#EXTINF:-1 tvg-id="CNN.us" group-title="News",CNN International
http://server/live/user/pass/2.m3u8
''';
    final result = await parseM3uString(playlist);

    expect(result.epgUrl, 'http://example.com/epg.xml');
    expect(result.entries, hasLength(2));

    final bbc = result.entries.first;
    expect(bbc.name, 'BBC One');
    expect(bbc.tvgId, 'BBC1.uk');
    expect(bbc.logo, 'http://logo/bbc1.png');
    expect(bbc.group, 'UK');
    expect(bbc.channelNumber, 1);
    expect(bbc.isVod, isFalse);
    expect(bbc.url, 'http://server/live/user/pass/1.ts');
  });

  test('titles containing commas survive', () async {
    const playlist = '''
#EXTM3U
#EXTINF:-1 group-title="Kids",Tom, Jerry & Friends
http://server/3.ts
''';
    final result = await parseM3uString(playlist);
    expect(result.entries.single.name, 'Tom, Jerry & Friends');
  });

  test('tolerates single-quoted and unquoted attribute values', () async {
    const playlist = '''
#EXTM3U
#EXTINF:0 tvg-id='abc' group-title=Sports,Channel A
http://server/a.ts
''';
    final result = await parseM3uString(playlist);
    final entry = result.entries.single;
    expect(entry.tvgId, 'abc');
    expect(entry.group, 'Sports');
  });

  test('EXTGRP sets the group when group-title is absent', () async {
    const playlist = '''
#EXTM3U
#EXTGRP:Documentaries
#EXTINF:-1,Nat Geo
http://server/ng.ts
''';
    final result = await parseM3uString(playlist);
    expect(result.entries.single.group, 'Documentaries');
  });

  test('classifies movie-style URLs as VOD', () async {
    const playlist = '''
#EXTM3U
#EXTINF:-1 group-title="Movies",Some Film
http://server/movie/user/pass/42.mkv
#EXTINF:-1,Live Channel
http://server/live/user/pass/7.ts
''';
    final result = await parseM3uString(playlist);
    expect(result.entries[0].isVod, isTrue);
    expect(result.entries[0].containerExtension, 'mkv');
    expect(result.entries[1].isVod, isFalse);
  });

  test('skips junk lines, bare URLs and blank lines', () async {
    const playlist = '''
#EXTM3U

#EXTVLCOPT:http-user-agent=Foo
http://orphan-url-without-extinf/x.ts
#EXTINF:-1,Real Channel

http://server/real.ts
''';
    final result = await parseM3uString(playlist);
    expect(result.entries, hasLength(1));
    expect(result.entries.single.name, 'Real Channel');
  });

  test(
    'falls back to tvg-name then Unnamed when the title is missing',
    () async {
      const playlist = '''
#EXTM3U
#EXTINF:-1 tvg-name="Named via attr",
http://server/1.ts
#EXTINF:-1,
http://server/2.ts
''';
      final result = await parseM3uString(playlist);
      expect(result.entries[0].name, 'Named via attr');
      expect(result.entries[1].name, 'Unnamed');
    },
  );

  test('streamId is stable and positive', () async {
    const playlist = '''
#EXTM3U
#EXTINF:-1,A
http://server/a.ts
''';
    final first = (await parseM3uString(playlist)).entries.single;
    final second = (await parseM3uString(playlist)).entries.single;
    expect(first.streamId, second.streamId);
    expect(first.streamId, greaterThan(0));
  });
}
