/// Keep provider titles for display. These keys are only used by local search.
final _marks = RegExp(r'[\u0610-\u061a\u0640\u064b-\u065f\u0670\u06d6-\u06ed]');
final _separators = RegExp(r'[^\p{L}\p{N}%_\\]+', unicode: true);
final _digits = RegExp('[٠-٩۰-۹]');
final _alef = RegExp('[أإآٱ]');
final _letterDigit = RegExp(r'(\p{L})(?=[0-9])', unicode: true);
final _digitLetter = RegExp(r'([0-9])(?=\p{L})', unicode: true);

String normalizeCatalogText(String text) => text
    .toLowerCase()
    .replaceAll(_marks, '')
    .replaceAll(_alef, 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ک', 'ك')
    .replaceAll('ی', 'ي')
    .replaceAll('ة', 'ه')
    .replaceAllMapped(_digits, (m) => '${m[0]!.codeUnitAt(0) & 15}')
    .replaceAllMapped(_letterDigit, (m) => '${m[1]} ')
    .replaceAllMapped(_digitLetter, (m) => '${m[1]} ')
    .replaceAll(_separators, ' ')
    .trim();

// The first two spellings are the English and Arabic search forms. Map
// whole words only: a search for MBC must not turn KMBC into the same brand.
const _aliases = [
  ['mbc', 'إم بي سي', 'ام بي سى', 'امبيسي', 'ام بي سي', 'm b c'],
  ['al jazeera', 'الجزيرة', 'aljazeera', 'al jazira'],
  ['al arabiya', 'العربية', 'alarabiya', 'al arabiya tv'],
  ['france 24', 'فرانس ٢٤', 'فرنسا 24'],
  ['bbc', 'بي بي سي'],
  ['cnn', 'سي إن إن'],
  ['bein', 'بي ان', 'بي إن', 'be in'],
  ['harry potter', 'هاري بوتر'],
  ['john wick', 'جون ويك'],
  ['game of thrones', 'صراع العروش'],
  ['bab al hara', 'باب الحارة', 'bab el hara'],
];

final _forms = {
  for (final group in _aliases)
    for (final spelling in group)
      normalizeCatalogText(spelling): (
        normalizeCatalogText(group[0]),
        normalizeCatalogText(group[1]),
      ),
};
final _spellings =
    (_forms.keys.toList()..sort((a, b) => b.length.compareTo(a.length)))
        .map(RegExp.escape)
        .join('|');
final _words = RegExp(
  '(^| )($_spellings)'
  r'(?= |$)',
);

String _alternate(String text, {required bool arabic}) =>
    text.replaceAllMapped(_words, (m) {
      final forms = _forms[m[2]]!;
      return '${m[1]}${arabic ? forms.$2 : forms.$1}';
    });

String catalogSearchKey(String title) {
  final original = normalizeCatalogText(title);
  final forms = {
    original,
    _alternate(original, arabic: false),
    _alternate(original, arabic: true),
  };
  return '|${forms.join('|')}|';
}

String catalogQuery(String input) =>
    _alternate(normalizeCatalogText(input), arabic: false);
