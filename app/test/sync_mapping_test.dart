import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/data/backend/sync_mapping.dart';
import 'package:zauxoflix/data/db/app_database.dart';

void main() {
  group('favorites mapping', () {
    test('CatalogKind maps to the backend ItemType and back', () {
      expect(favoriteItemType(CatalogKind.live).wire, 'LIVE');
      expect(favoriteItemType(CatalogKind.vod).wire, 'MOVIE');
      expect(favoriteItemType(CatalogKind.series).wire, 'SERIES');

      for (final kind in CatalogKind.values) {
        expect(favoriteKindFrom(favoriteItemType(kind)), kind);
      }
    });

    test('BackendItemType.parse tolerates unknown values', () {
      expect(BackendItemType.parse('MOVIE'), BackendItemType.movie);
      expect(BackendItemType.parse('nope'), isNull);
      expect(BackendItemType.parse(null), isNull);
    });
  });

  group('progress mapping', () {
    test('a movie maps to (MOVIE, streamId, "")', () {
      final key = progressKey(WatchKind.movie, 42, null)!;
      expect(key.itemType, BackendItemType.movie);
      expect(key.itemId, '42');
      expect(key.episodeId, '');
    });

    test('an episode maps to (SERIES, seriesId, episodeId)', () {
      final key = progressKey(WatchKind.episode, 500, 7)!;
      expect(key.itemType, BackendItemType.series);
      expect(key.itemId, '7');
      expect(key.episodeId, '500');
    });

    test('an episode with no series id is not representable', () {
      expect(progressKey(WatchKind.episode, 500, null), isNull);
    });

    test('round-trips a movie back to a local ref', () {
      final ref = localProgressRef(BackendItemType.movie, '42', '')!;
      expect(ref.kind, WatchKind.movie);
      expect(ref.itemId, 42);
      expect(ref.seriesId, isNull);
    });

    test('round-trips an episode back to a local ref', () {
      final ref = localProgressRef(BackendItemType.series, '7', '500')!;
      expect(ref.kind, WatchKind.episode);
      expect(ref.itemId, 500);
      expect(ref.seriesId, 7);
    });

    test('live and series-level rows are dropped on the way in', () {
      expect(localProgressRef(BackendItemType.live, '1', ''), isNull);
      expect(localProgressRef(BackendItemType.series, '7', ''), isNull);
    });
  });
}
