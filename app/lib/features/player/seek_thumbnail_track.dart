/// The image playlist format used by HLS trick play. Each segment can be a
/// single image or a row-major grid of frames.
class SeekThumbnailTrack {
  SeekThumbnailTrack._(this._segments);

  final List<_ImageSegment> _segments;

  static Uri? imagePlaylist(String manifest, Uri master) {
    for (final raw in manifest.split('\n')) {
      final line = raw.trim();
      if (!line.startsWith('#EXT-X-IMAGE-STREAM-INF:')) continue;
      final uri = _attribute(line, 'URI');
      final codecs = _attribute(line, 'CODECS');
      if (uri == null || (codecs != null && codecs.toLowerCase() != 'jpeg')) {
        continue;
      }
      final image = _resolveHttp(master, uri);
      if (image != null) return image;
    }
    return null;
  }

  static SeekThumbnailTrack? parse(String manifest, Uri playlist) {
    final lines = manifest.split('\n').map((line) => line.trim()).toList();
    if (!lines.contains('#EXT-X-IMAGES-ONLY') ||
        !lines.contains('#EXT-X-ENDLIST')) {
      return null;
    }
    final segments = <_ImageSegment>[];
    var start = 0;
    var length = 0;
    _TileGrid? grid;
    var invalidGrid = false;
    for (final line in lines) {
      if (line.startsWith('#EXTINF:')) {
        length = _milliseconds(line.substring(8).split(',').first) ?? 0;
      } else if (line.startsWith('#EXT-X-TILES:')) {
        grid = _TileGrid.parse(line);
        invalidGrid = grid == null;
      } else if (line.isNotEmpty && !line.startsWith('#') && length > 0) {
        final uri = _resolveHttp(playlist, line);
        if (uri != null && !invalidGrid) {
          segments.add(_ImageSegment(start, start + length, uri, grid));
        }
        start += length;
        length = 0;
        grid = null;
        invalidGrid = false;
      }
    }
    return segments.isEmpty ? null : SeekThumbnailTrack._(segments);
  }

  SeekThumbnail? at(Duration time) {
    final milliseconds = time.inMilliseconds;
    var left = 0;
    var right = _segments.length - 1;
    while (left <= right) {
      final middle = (left + right) ~/ 2;
      final segment = _segments[middle];
      if (milliseconds < segment.start) {
        right = middle - 1;
      } else if (milliseconds >= segment.end) {
        left = middle + 1;
      } else {
        final grid = segment.grid;
        final offset = milliseconds - segment.start;
        final index = grid == null
            ? 0
            : (offset ~/ grid.duration).clamp(0, grid.columns * grid.rows - 1);
        return SeekThumbnail(
          uri: segment.uri,
          column: grid == null ? 0 : index % grid.columns,
          row: grid == null ? 0 : index ~/ grid.columns,
          columns: grid?.columns ?? 1,
          rows: grid?.rows ?? 1,
        );
      }
    }
    return null;
  }
}

class SeekThumbnail {
  const SeekThumbnail({
    required this.uri,
    required this.column,
    required this.row,
    required this.columns,
    required this.rows,
  });

  final Uri uri;
  final int column, row, columns, rows;
}

class _ImageSegment {
  const _ImageSegment(this.start, this.end, this.uri, this.grid);

  final int start, end;
  final Uri uri;
  final _TileGrid? grid;
}

class _TileGrid {
  const _TileGrid(this.columns, this.rows, this.duration);

  final int columns, rows, duration;

  static _TileGrid? parse(String line) {
    final match = RegExp(
      r'^(\d+)x(\d+)$',
    ).firstMatch(_attribute(line, 'LAYOUT') ?? '');
    final size = RegExp(
      r'^(\d+)x(\d+)$',
    ).firstMatch(_attribute(line, 'RESOLUTION') ?? '');
    final duration = _milliseconds(_attribute(line, 'DURATION') ?? '');
    if (match == null || size == null || duration == null) return null;
    final columns = int.tryParse(match[1]!) ?? 0;
    final rows = int.tryParse(match[2]!) ?? 0;
    final width = int.tryParse(size[1]!) ?? 0;
    final height = int.tryParse(size[2]!) ?? 0;
    if (columns < 1 ||
        rows < 1 ||
        width < 1 ||
        height < 1 ||
        columns * rows > 200 ||
        columns * width > 8192 ||
        rows * height > 8192) {
      return null;
    }
    return _TileGrid(columns, rows, duration);
  }
}

String? _attribute(String line, String key) {
  final match = RegExp('(?:^|[:,])$key=(?:"([^"]+)"|([^,]+))').firstMatch(line);
  return match?[1] ?? match?[2];
}

int? _milliseconds(String seconds) {
  final value = double.tryParse(seconds);
  if (value == null || !value.isFinite || value <= 0 || value > 86400) {
    return null;
  }
  final milliseconds = (value * 1000).round();
  return milliseconds > 0 ? milliseconds : null;
}

Uri? _resolveHttp(Uri base, String path) {
  final ref = Uri.tryParse(path);
  if (ref == null) return null;
  final result = base.resolveUri(ref);
  return (result.scheme == 'http' || result.scheme == 'https') &&
          result.hasAuthority
      ? result
      : null;
}
