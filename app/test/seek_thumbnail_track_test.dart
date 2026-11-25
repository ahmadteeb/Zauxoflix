import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/features/player/seek_thumbnail_track.dart';

void main() {
  final playlist = Uri.parse('https://example.test/vod/images/preview.m3u8');

  test('selects the supported image rendition and resolves its URI', () {
    final parsed = SeekThumbnailTrack.imagePlaylist('''
#EXTM3U
#EXT-X-IMAGE-STREAM-INF:CODECS="unknown",URI="wrong.m3u8"
#EXT-X-IMAGE-STREAM-INF:CODECS="jpeg",URI="images/preview.m3u8"
''', Uri.parse('https://example.test/vod/master.m3u8'));
    expect(parsed, playlist);
  });

  test('maps seek times to the right sprite cells and single images', () {
    final track = SeekThumbnailTrack.parse('''
#EXTM3U
#EXT-X-IMAGES-ONLY
#EXTINF:12,
#EXT-X-TILES:RESOLUTION=160x90,LAYOUT=2x2,DURATION=3
tiles/first.jpg
#EXTINF:6,
last.jpg
#EXT-X-ENDLIST
''', playlist)!;
    final tile = track.at(const Duration(seconds: 7))!;
    expect(tile.uri.path, '/vod/images/tiles/first.jpg');
    expect((tile.column, tile.row, tile.columns, tile.rows), (0, 1, 2, 2));
    final image = track.at(const Duration(seconds: 12))!;
    expect(image.uri.path, '/vod/images/last.jpg');
    expect((image.columns, image.rows), (1, 1));
    expect(track.at(const Duration(seconds: 18)), isNull);
  });

  test('skips incomplete media playlists and non-HTTP resources', () {
    expect(
      SeekThumbnailTrack.parse('#EXTM3U\n#EXTINF:8,\nclip.ts', playlist),
      isNull,
    );
    expect(
      SeekThumbnailTrack.parse('''
#EXTM3U
#EXT-X-IMAGES-ONLY
#EXTINF:8,
file:///private/preview.jpg
#EXT-X-ENDLIST
''', playlist),
      isNull,
    );
  });
}
