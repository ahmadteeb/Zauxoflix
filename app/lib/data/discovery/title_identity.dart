import '../catalog_search.dart';

final _imdb = RegExp(r'^tt[0-9]{7,12}$');
final _year = RegExp(r'\b(19\d{2}|20\d{2})\b');
final _suffix = RegExp(
  r'(?:\s*[\[(](?:19|20)\d{2}[\])]|[\s._-]+(?:2160p|1080p|720p|4k|uhd|fhd|hd))\s*$',
  caseSensitive: false,
);
final _prefix = RegExp(
  r'^\s*(?:\[?(?:ar|en|fr|de|us|uk)\]?\s*[|:]\s*)',
  caseSensitive: false,
);

String? validImdb(Object? value) =>
    value is String && _imdb.hasMatch(value.trim()) ? value.trim() : null;
String? providerExternalId(Map<String, dynamic> json) {
  final imdb = validImdb(json['imdb_id']) ?? validImdb(json['imdb']);
  if (imdb != null) return imdb;
  final tmdb = int.tryParse('${json['tmdb_id'] ?? json['tmdb']}');
  return tmdb != null && tmdb > 0 ? 'tmdb:$tmdb' : null;
}

int? titleYear(String? date) =>
    int.tryParse(_year.firstMatch(date ?? '')?.group(1) ?? '');
({String name, int? year}) splitTitle(String original) {
  var name = original.replaceFirst(_prefix, '').trim();
  int? year;
  while (true) {
    final suffix = _suffix.firstMatch(name);
    if (suffix == null || suffix.start == 0) break;
    year ??= titleYear(suffix.group(0));
    name = name.substring(0, suffix.start).trim();
  }
  return (name: name, year: year);
}

String discoveryName(String name) => catalogQuery(splitTitle(name).name);
