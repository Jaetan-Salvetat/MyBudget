library;

import 'accent_fold.dart';

final RegExp _leadingMarkers = RegExp(r'^[\s*#!.\-]+');
final RegExp _trailingMarkers = RegExp(r'[\s*#!.\-]+$');
final RegExp _longCode = RegExp(r'\b\d{5,}\b');
final RegExp _quantity = RegExp(
  r'\b\d+(?:[.,]\d+)?\s?(?:x\s?\d+(?:[.,]\d+)?\s?)?'
  r'(?:g|gr|grs|kg|l|cl|ml|mg|m|cm|mm|w|d|p|pl|t|tr|rlx|dos|st|pce|pcs)\b',
  caseSensitive: false,
);
final RegExp _count = RegExp(
  r'(?:\b|(?<=\s))x\s?\d+\b|\b\d+\s?x\b',
  caseSensitive: false,
);
final RegExp _fraction = RegExp(r'\b\d/\d\b');
final RegExp _percent = RegExp(
  r'\b\d+(?:[.,]\d+)?\s?%(?:\s?mg)?',
  caseSensitive: false,
);
final RegExp _leadingCount = RegExp(r'^\d{1,2}\s+(?=\D)');
final RegExp _loneNumber = RegExp(r'\b\d+(?:[.,]\d+)?\b');
final RegExp _spaces = RegExp(r'\s+');
final RegExp _dotGlue = RegExp(r'(?<=[^\W\d])\.(?=[^\W\d])');
final RegExp _edgePunctuation = RegExp(r'^[ .,;:\-*]+|[ .,;:\-*]+$');

const Map<String, String> _substitutions = {
  '’': "'",
  '‘': "'",
  '‛': "'",
  '`': "'",
  '´': "'",
  'ʼ': "'",
  '–': '-',
  '—': '-',
  '‒': '-',
  '―': '-',
  '−': '-',
  ' ': ' ',
  ' ': ' ',
};

final RegExp _repeatedPunctuation = RegExp(
  '([' r'''&+/\\,;:!?()\[\]{}<>|="«»*#~.'\-_@%''' r'])\1+',
);

final RegExp _spacedPunctuation = RegExp(
  '([' r'&+/\\,;:!?()\[\]{}<>|="«»*#~' '])',
);

const List<List<int>> _combiningRanges = [
  [0x0300, 0x0370],
  [0x1AB0, 0x1B00],
  [0x1DC0, 0x1E00],
  [0x20D0, 0x2100],
  [0xFE20, 0xFE30],
];

bool _isCombining(String char) {
  final codePoint = char.codeUnitAt(0);
  for (final range in _combiningRanges) {
    if (codePoint >= range[0] && codePoint < range[1]) return true;
  }
  return false;
}

String normalizeQuery(String text) {
  final buffer = StringBuffer();
  for (final char in text.split('')) {
    if (_isCombining(char)) continue;
    final folded = accentFold[char] ?? char;
    buffer.write(_substitutions[folded] ?? folded);
  }
  var out = buffer.toString().toLowerCase();
  out = out.replaceAllMapped(_repeatedPunctuation, (match) => match[1]!);
  out = out.replaceAllMapped(_spacedPunctuation, (match) => ' ${match[1]} ');
  return out.replaceAll(_spaces, ' ').trim();
}

String normalizeReceiptLine(String line) {
  var text = line.replaceFirst(_leadingMarkers, '');
  text = text.replaceFirst(_trailingMarkers, '');
  text = text.replaceAll(_longCode, ' ');
  text = text.replaceAll(_percent, ' ');
  text = text.replaceAll(_quantity, ' ');
  text = text.replaceAll(_count, ' ');
  text = text.replaceAll(_fraction, ' ');
  text = text.replaceFirst(_leadingCount, '');
  text = text.replaceAll(_loneNumber, ' ');
  text = text.replaceAll(_dotGlue, ' ');
  text = text.replaceAll('/', ' ');
  text = text.replaceAll(_spaces, ' ').replaceAll(_edgePunctuation, '');
  return normalizeQuery(text.isEmpty ? line : text);
}
