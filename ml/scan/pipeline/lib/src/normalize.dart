/// Forme canonique d'un texte avant le modèle : le ticket comme la saisie.
///
/// Miroir exact de `ml/classifier/serving/normalize.py`, vérifié par
/// `test/normalization_test.dart` sur les fixtures
/// `receipt_line_normalization.json` et `query_normalization.json`. Une
/// divergence ici enverrait au modèle un texte qu'il n'a pas vu à
/// l'entraînement.
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

/// Apostrophes typographiques, tirets longs et espaces insécables : ce que les
/// claviers et les copier-coller glissent à la place du caractère ASCII.
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

/// Écrite en toutes lettres et non `[^\w\s]` : `\w` couvre les lettres
/// accentuées chez Python et l'ASCII seul chez Dart, et le miroir divergerait
/// sur « ø » ou « æ ».
final RegExp _repeatedPunctuation = RegExp(
  '([' r'''&+/\\,;:!?()\[\]{}<>|="«»*#~.'\-_@%''' r'])\1+',
);

/// La ponctuation qui colle deux mots : « father &son » est « father & son ».
final RegExp _spacedPunctuation = RegExp(
  '([' r'&+/\\,;:!?()\[\]{}<>|="«»*#~' '])',
);

/// Un texte peut arriver décomposé (macOS et iOS écrivent « café » en NFD) : la
/// lettre est alors nue et l'accent la suit en caractère séparé, qu'aucune table
/// de précomposés ne peut attraper. Mêmes plages que la référence Python.
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

/// Minuscules, sans accents, ponctuation décollée — la forme exacte du corpus.
///
/// Ce que cette fonction traite, le modèle n'a pas à l'apprendre : « father
/// &son » et « Father & Son » sont la même chaîne avant de l'atteindre.
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

/// Un libellé imprimé, débarrassé de ce que personne ne tape : astérisques de
/// tête, code-barres, contenance (« 4X125G »), compteur (« X6 »). Rien n'est
/// réécrit, on ne fait que retirer, puis la forme canonique est la même que
/// celle d'une saisie.
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
