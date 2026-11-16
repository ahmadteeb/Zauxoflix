import 'dart:convert';

/// Tolerant M3U/M3U8 playlist parser. Real-world playlists are messy:
/// attributes may be unquoted or single-quoted, titles contain commas,
/// #EXTGRP overrides groups, and entries can miss EXTINF entirely.
class M3uEntry {
  const M3uEntry({
    required this.name,
    required this.url,
    this.tvgId,
    this.logo,
    this.group,
    this.channelNumber,
  });

  final String name;
  final String url;
  final String? tvgId;
  final String? logo;
  final String? group;
  final int? channelNumber;

  static const _vodExtensions = {
    'mp4',
    'mkv',
    'avi',
    'mov',
    'm4v',
    'webm',
    'flv',
    'wmv',
    'mpg',
    'mpeg',
  };

  bool get isVod {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    if (path.contains('/movie/') || path.contains('/series/')) return true;
    final dot = path.lastIndexOf('.');
    if (dot < 0) return false;
    return _vodExtensions.contains(path.substring(dot + 1));
  }

  String? get containerExtension {
    final path = Uri.tryParse(url)?.path ?? url;
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return null;
    final ext = path.substring(dot + 1).toLowerCase();
    return ext.length <= 5 ? ext : null;
  }

  /// Stable positive 31-bit FNV-1a hash of the URL — persists as streamId so
  /// selections survive re-syncs without a playlist-order dependency.
  int get streamId {
    var hash = 0x811c9dc5;
    for (final unit in url.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }
}

class M3uParseResult {
  const M3uParseResult({required this.entries, this.epgUrl});

  final List<M3uEntry> entries;

  /// From url-tvg / x-tvg-url on the #EXTM3U header, if present.
  final String? epgUrl;
}

final _attrPattern = RegExp('''([A-Za-z0-9_-]+)=("[^"]*"|'[^']*'|[^\\s",]+)''');

String _unquote(String v) {
  if (v.length >= 2 &&
      ((v.startsWith('"') && v.endsWith('"')) ||
          (v.startsWith("'") && v.endsWith("'")))) {
    return v.substring(1, v.length - 1);
  }
  return v;
}

Future<M3uParseResult> parseM3uLines(Stream<String> lines) async {
  final entries = <M3uEntry>[];
  String? epgUrl;

  Map<String, String> attrs = const {};
  String? title;
  String? extGrp;
  var sawExtinf = false;

  await for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;

    if (line.startsWith('#EXTM3U')) {
      final headerAttrs = {
        for (final m in _attrPattern.allMatches(line))
          m.group(1)!.toLowerCase(): _unquote(m.group(2)!),
      };
      epgUrl ??= headerAttrs['url-tvg'] ?? headerAttrs['x-tvg-url'];
      continue;
    }

    if (line.startsWith('#EXTINF')) {
      attrs = {
        for (final m in _attrPattern.allMatches(line))
          m.group(1)!.toLowerCase(): _unquote(m.group(2)!),
      };
      // Title = text after the first comma once attributes are stripped out.
      final stripped = line.replaceAll(_attrPattern, '');
      final comma = stripped.indexOf(',');
      title = comma < 0 ? '' : stripped.substring(comma + 1).trim();
      sawExtinf = true;
      continue;
    }

    if (line.startsWith('#EXTGRP:')) {
      extGrp = line.substring(8).trim();
      continue;
    }

    if (line.startsWith('#')) continue;

    // Non-comment line = stream URL, closing the pending entry (if any).
    if (!sawExtinf) continue; // bare URL with no metadata — skip
    final name = (title == null || title.isEmpty)
        ? (attrs['tvg-name'] ?? 'Unnamed')
        : title;
    entries.add(
      M3uEntry(
        name: name,
        url: line,
        tvgId: _emptyToNull(attrs['tvg-id']),
        logo: _emptyToNull(attrs['tvg-logo']),
        group: _emptyToNull(attrs['group-title'] ?? extGrp),
        channelNumber: int.tryParse(
          attrs['tvg-chno'] ?? attrs['ch-number'] ?? '',
        ),
      ),
    );
    attrs = const {};
    title = null;
    sawExtinf = false;
  }

  return M3uParseResult(entries: entries, epgUrl: epgUrl);
}

String? _emptyToNull(String? v) => (v == null || v.isEmpty) ? null : v;

Future<M3uParseResult> parseM3uString(String content) =>
    parseM3uLines(Stream.value(content).transform(const LineSplitter()));
