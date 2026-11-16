import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/data/epg/xmltv_parser.dart';

Future<List<XmltvProgramme>> parseAll(
  String xml, {
  Set<String>? wantedChannels,
  DateTime? minEnd,
  DateTime? maxStart,
}) async {
  final batches = await parseXmltv(
    Stream.value(xml),
    wantedChannels: wantedChannels,
    minEnd: minEnd,
    maxStart: maxStart,
    batchSize: 2,
  ).toList();
  return [for (final b in batches) ...b];
}

void main() {
  group('parseXmltvDate', () {
    test('parses full timestamp with offset', () {
      expect(
        parseXmltvDate('20260715120000 +0300'),
        DateTime.utc(2026, 7, 15, 9, 0, 0),
      );
    });

    test('assumes UTC without offset and pads truncated stamps', () {
      expect(parseXmltvDate('202607151230'), DateTime.utc(2026, 7, 15, 12, 30));
    });

    test('rejects garbage', () {
      expect(parseXmltvDate('not-a-date'), isNull);
      expect(parseXmltvDate(null), isNull);
    });
  });

  test('parses programmes with title, desc and channel', () async {
    const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <channel id="BBC1.uk"><display-name>BBC One</display-name></channel>
  <programme start="20260715120000 +0000" stop="20260715130000 +0000" channel="BBC1.uk">
    <title lang="en">News at Noon</title>
    <desc lang="en">Headlines and weather.</desc>
  </programme>
  <programme start="20260715130000 +0000" stop="20260715140000 +0000" channel="BBC1.uk">
    <title>Afternoon Show</title>
  </programme>
</tv>
''';
    final programmes = await parseAll(xml);
    expect(programmes, hasLength(2));
    expect(programmes[0].channelId, 'bbc1.uk');
    expect(programmes[0].title, 'News at Noon');
    expect(programmes[0].description, 'Headlines and weather.');
    expect(programmes[0].start, DateTime.utc(2026, 7, 15, 12));
    expect(programmes[0].end, DateTime.utc(2026, 7, 15, 13));
    expect(programmes[1].description, isNull);
  });

  test('filters unwanted channels and out-of-window programmes', () async {
    const xml = '''
<tv>
  <programme start="20260715120000" stop="20260715130000" channel="Keep.me">
    <title>Kept</title>
  </programme>
  <programme start="20260715120000" stop="20260715130000" channel="Drop.me">
    <title>Dropped channel</title>
  </programme>
  <programme start="20260710120000" stop="20260710130000" channel="Keep.me">
    <title>Too old</title>
  </programme>
  <programme start="20260830120000" stop="20260830130000" channel="Keep.me">
    <title>Too far ahead</title>
  </programme>
</tv>
''';
    final programmes = await parseAll(
      xml,
      wantedChannels: {'keep.me'},
      minEnd: DateTime.utc(2026, 7, 15),
      maxStart: DateTime.utc(2026, 7, 18),
    );
    expect(programmes, hasLength(1));
    expect(programmes.single.title, 'Kept');
  });

  test('skips malformed programmes without crashing', () async {
    const xml = '''
<tv>
  <programme start="garbage" stop="20260715130000" channel="a">
    <title>Bad start</title>
  </programme>
  <programme start="20260715130000" stop="20260715120000" channel="a">
    <title>Ends before it starts</title>
  </programme>
  <programme start="20260715120000" stop="20260715130000" channel="">
    <title>No channel</title>
  </programme>
  <programme start="20260715120000" stop="20260715130000" channel="ok">
    <title>Good</title>
  </programme>
</tv>
''';
    final programmes = await parseAll(xml);
    expect(programmes, hasLength(1));
    expect(programmes.single.title, 'Good');
  });

  test('handles CDATA and entities in text', () async {
    const xml = '''
<tv>
  <programme start="20260715120000" stop="20260715130000" channel="a">
    <title><![CDATA[Tom & Jerry]]></title>
    <desc>Cat &amp; mouse.</desc>
  </programme>
</tv>
''';
    final programmes = await parseAll(xml);
    expect(programmes.single.title, 'Tom & Jerry');
    expect(programmes.single.description, 'Cat & mouse.');
  });

  test('untitled programmes get a placeholder title', () async {
    const xml = '''
<tv>
  <programme start="20260715120000" stop="20260715130000" channel="a"/>
</tv>
''';
    final programmes = await parseAll(xml);
    expect(programmes.single.title, 'No title');
  });

  test('respects batch size across the stream', () async {
    final buffer = StringBuffer('<tv>');
    for (var i = 0; i < 5; i++) {
      buffer.write('''
<programme start="202607151${i}0000" stop="202607151${i}3000" channel="a">
  <title>P$i</title>
</programme>''');
    }
    buffer.write('</tv>');

    final batches = await parseXmltv(
      Stream.value(buffer.toString()),
      batchSize: 2,
    ).toList();
    expect(batches.map((b) => b.length).toList(), [2, 2, 1]);
  });
}
