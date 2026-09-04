library;

import 'dart:math' as math;

import 'accent_fold.dart';
import 'lines.dart';

final RegExp pricePattern = RegExp(r'^-?\d{1,4}[.,]\d{2}$');
final RegExp quantityPattern = RegExp(r'^(\d{1,2})[xX*](-?\d{1,4}[.,]\d{2})$');
final RegExp weightPattern = RegExp(
  r'^\d{1,3}[.,]\d{1,3}\s?[Kk]?[Gg][xX*]\d{1,4}[.,]\d{1,2}.*$',
);
final RegExp _missingSeparatorTotalPattern = RegExp(r'(\d{3,6})\s*$');
final RegExp _articleCountPattern = RegExp(r'(\d{1,3})ARTICLE');
final RegExp _phonePattern = RegExp(r'(?<!\d)0\d([.\-])\d{2}(?:\1\d{2}){3}(?!\d)');

final RegExp _datePattern = RegExp(
  r'(\d{1,2})[/.-](\d{1,2})[/.-](\d{4}|\d{2}(?![\d./-]))',
);
final RegExp _boundedDatePattern = RegExp(
  r'(?<![\d/.\-])(\d{1,2})[/.-](\d{1,2})[/.-](\d{4}|\d{2})(?![\d/.\-])',
);
final RegExp _spacedDatePattern = RegExp(
  r'(?<![\d/.\-])(\d{1,2}) (\d{1,2}) (\d{4})(?![\d/.\-])',
);
final RegExp _damagedLiteralDatePattern = RegExp(
  r'(?<![A-Z\d])(\d{1,2})(?:ER)? ?([A-Z]{5,9}) ?(\d{4}|\d{2})(?![\d/.\-])',
  caseSensitive: false,
);
const List<String> _fullMonthNames = [
  'JANVIER',
  'FEVRIER',
  'MARS',
  'AVRIL',
  'MAI',
  'JUIN',
  'JUILLET',
  'AOUT',
  'SEPTEMBRE',
  'OCTOBRE',
  'NOVEMBRE',
  'DECEMBRE',
];
const int _damagedMonthMinLength = 5;
const int _damagedMonthLongLength = 7;

const List<String> _monthNames = [
  'JANV|JAN',
  'FEVR|FEV',
  'MARS|MAR',
  'AVRIL|AVR',
  'MAI',
  'JUIN|JUN',
  'JUILLET|JUIL|JUL',
  'AOUT|AOU',
  'SEPTEMBRE|SEPT|SEP',
  'OCTOBRE|OCT',
  'NOVEMBRE|NOV',
  'DECEMBRE|DEC',
];

final RegExp _literalDatePattern = RegExp(
  r'(\d{1,2})(?:ER)?[/.\- ]?(' +
      _monthNames.join('|') +
      r')[A-Z]*[/.\- ]?(\d{4}|\d{2})',
  caseSensitive: false,
);

const int _minYear = 1990;
const int _maxYear = 2035;

const int _centuryPivot = 70;
const int _maxDay = 31;
const int _maxMonth = 12;
final RegExp _integerPattern = RegExp(r'^-?\d{1,4}$');
final RegExp _decimalsPattern = RegExp(r'^[.,]?\d{2}$');
final RegExp _leaderDotsPattern = RegExp(r'^[.…]+');

const List<String> discountWords = [
  'REMISE',
  'PROMO',
  'DISCOUNT',
];

const List<String> totalWords = [
  'TOTAL',
  'TOT',
  'PAYER',
  'MONTANT DU',
  'NET A REGLER',
  'A REGLER',
  'DOIT',
  'PRIX TTC',
  'MONTANT TTC',
];

const String fuzzyTotalWord = 'TOTAL';
const int fuzzyTotalMaxDistance = 1;
const int fuzzyTotalMinTokenLength = 4;
const int fuzzyTotalMaxTokenLength = 6;

const List<String> subtotalWords = [
  'SOUS-TOTAL',
  'SOUS TOTAL',
  'SUBTOTAL',
  'SUB-TOTAL',
  'S/TOTAL',
  'S/TOT',
  'AMOUNT',
  'TAXABLE',
];

const List<String> stopWords = [
  'TOTAL',
  'PAYER',
  'SOUS-TOTAL',
  'TVA',
  'TUA',
  'CB ',
  'CARTE BANCAIRE',
  'ESPECES',
  'RENDU',
  'A RENDRE',
  'MONNAIE',
  'CHEQUE',
  'ARTICLE(',
  'ARTICLES',
  'MERCI',
  'TEL',
  'CAISSE',
  'TTC',
  'EMV',
  'SANS CONTACT',
  'VISITE',
  'INCL',
  'TAX',
  'VISA',
  'MASTERCARD',
  'CREDIT',
  'SERVER',
  'WELCOME',
  'FIDELITE',
  'CARTE BLEUE',
  'TOTAUX',
  'SOLDE',
  'PAIEMENT',
  'REGLEMENT',
  'PERCU',
  'RECU',
];

const List<String> excludedTotalWords = [
  'HT',
  'TVA',
  'TUA',
  'ELIGIBLE',
  'FRANC',
  'FRF',
];

const List<String> paymentWords = [
  'CB',
  'CARTE BANCAIRE',
  'CARTES BANCAIRES',
  'CARTE BLEUE',
  'VISA',
  'MASTERCARD',
  'SANS CONTACT',
  'EMV',
  'ESPECES',
  'CHEQUE',
  'PAIEMENT',
  'REGLEMENT',
  'MONTANT PERCU',
  'PERCU',
  'RECU',
];
const List<String> tvaWords = ['TVA', 'TUA', 'TAX'];
const List<String> taxInclusiveWords = ['INCL'];

class ExtractedItem {
  ExtractedItem({
    required this.name,
    required this.amount,
    required this.discount,
    this.lineIndex,
  });

  String name;
  final double amount;
  double discount;

  final int? lineIndex;
}

class ExtractedReceipt {
  const ExtractedReceipt({
    required this.store,
    required this.date,
    required this.total,
    required this.subtotal,
    required this.payment,
    required this.items,
    this.tvaTtcSum,
    this.printedCount,
    this.fallbackReferences = const [],
  });

  final String? store;
  final String? date;
  final double? total;
  final double? subtotal;
  final double? payment;
  final List<ExtractedItem> items;
  final double? tvaTtcSum;
  final int? printedCount;
  final List<double> fallbackReferences;

  double get itemsSum => roundCents(
    items.fold(0.0, (sum, item) => sum + item.amount - item.discount),
  );

  bool get checksumOk {
    if (_matches(total) || _matches(subtotal)) return true;
    if (total == null && _matches(tvaTtcSum)) return true;
    if (total == null && fallbackReferences.any(_matches)) return true;
    if (_matches(payment)) {
      if (total == null) return true;
      if (printedCount == items.length) return true;
    }
    return false;
  }

  double? get verifiedTotal {
    if (_matches(total)) return total;
    if (_matches(subtotal)) return subtotal;
    if (total == null && _matches(tvaTtcSum)) return tvaTtcSum;
    if (total == null) {
      for (final candidate in fallbackReferences) {
        if (_matches(candidate)) return candidate;
      }
    }
    if (checksumOk && _matches(payment)) return payment;
    return null;
  }

  bool _matches(double? reference) =>
      reference != null && (itemsSum - reference).abs() < 0.005;
}

double roundCents(double value) => (value * 100).round() / 100;

final RegExp _glyphPricePattern = RegExp(r'^-?[\dIlOoS]{1,4}[.,][\dIlOoS]{2}$');
const Map<String, String> _glyphTranslation = {
  'I': '1',
  'l': '1',
  'O': '0',
  'o': '0',
  'S': '5',
};

final RegExp _trailingLetterPattern = RegExp(r'([.,]\d{2})[A-Za-z]$');
const String _damagedSeparator = ';';
const String _leadingPunctuation = ':';

double? parsePrice(String text) {
  final normalized = _stripLeading(
    text.replaceAll(_damagedSeparator, ','),
    _leadingPunctuation,
  );
  var cleaned = _stripEdges(
    normalized.replaceAll('€', '').replaceAll(r'$', ''),
    'eE',
  );
  cleaned = cleaned.replaceFirst(_leaderDotsPattern, '');
  cleaned = cleaned.replaceFirstMapped(
    _trailingLetterPattern,
    (match) => match.group(1)!,
  );
  if (!pricePattern.hasMatch(cleaned)) {
    final deglyphed = _deglyphed(cleaned);
    if (deglyphed == null) return null;
    cleaned = deglyphed;
  }
  return double.tryParse(cleaned.replaceAll(',', '.'));
}

String _stripLeading(String text, String chars) {
  var start = 0;
  while (start < text.length && chars.contains(text[start])) {
    start++;
  }
  return text.substring(start);
}

String _stripEdges(String text, String chars) {
  var start = 0;
  var end = text.length;
  while (start < end && chars.contains(text[start])) {
    start++;
  }
  while (end > start && chars.contains(text[end - 1])) {
    end--;
  }
  return text.substring(start, end);
}

String? _deglyphed(String text) {
  if (!_glyphPricePattern.hasMatch(text)) return null;
  final digits = _countDigits(text);
  final letters = _countLetters(text);
  if (letters == 0 || digits < 2 * letters) return null;
  final candidate = text.split('').map((char) {
    return _glyphTranslation[char] ?? char;
  }).join();
  return pricePattern.hasMatch(candidate) ? candidate : null;
}

final RegExp _letterPattern = RegExp(r'\p{L}', unicode: true);
final RegExp _digitPattern = RegExp(r'[0-9]');

int _countDigits(String text) => _digitPattern.allMatches(text).length;

int _countLetters(String text) => _letterPattern.allMatches(text).length;

final RegExp _fragmentHeadPattern = RegExp(r'^-?\d{1,4}[.,]$');
final RegExp _fragmentTailPattern = RegExp(r'^\d{2}[€eE]?$');

PhysicalLine mergePriceFragments(PhysicalLine line) {
  final words = line.words;
  final merged = <Word>[];
  var index = 0;
  while (index < words.length) {
    final word = words[index];
    if (index + 1 < words.length) {
      final tail = words[index + 1];
      final gap = tail.left - word.right;
      final closeEnough = gap < (word.bottom - word.top) * 1.2;
      if (_fragmentHeadPattern.hasMatch(word.text) &&
          _fragmentTailPattern.hasMatch(tail.text) &&
          closeEnough) {
        merged.add(
          Word(
            text: word.text + tail.text,
            left: word.left,
            top: word.top < tail.top ? word.top : tail.top,
            right: tail.right,
            bottom: word.bottom > tail.bottom ? word.bottom : tail.bottom,
            confidence: _minConfidence(word, tail),
          ),
        );
        index += 2;
        continue;
      }
    }
    merged.add(word);
    index += 1;
  }
  return PhysicalLine(words: merged);
}

double? _minConfidence(Word first, Word second) {
  final scores = [
    for (final word in [first, second])
      if (word.confidence != null) word.confidence!,
  ];
  if (scores.isEmpty) return null;
  return scores.reduce((a, b) => a < b ? a : b);
}

final RegExp _gluedPricePattern = RegExp(
  r'^[A-Za-z]{1,5}(-?\d{1,4}[.,]\d{2})[€eE]?$',
);

class PricedWord {
  const PricedWord(this.price, this.word);

  final double price;
  final Word word;
}

PricedWord? rightmostPrice(PhysicalLine line) {
  for (final word in line.words.reversed) {
    final price = parsePrice(word.text);
    if (price != null) return PricedWord(price, word);
  }
  for (final word in line.words.reversed) {
    final glued = _gluedPricePattern.firstMatch(word.text);
    if (glued != null) {
      return PricedWord(
        double.parse(glued.group(1)!.replaceAll(',', '.')),
        word,
      );
    }
  }
  if (containsTotal(line.text)) {
    return _trailingJunkPrice(line) ?? _splitPrice(line);
  }
  return null;
}

final RegExp laxPricePattern = RegExp(r'(?<![\d.,])(-?\d{1,4}[.,]\d{2})(?![\d.,%])');

List<PricedWord> priceCandidates(PhysicalLine line, {required bool lax}) {
  final strict = rightmostPrice(line);
  if (strict != null) return [strict];
  if (!lax) return const [];
  final candidates = <PricedWord>[];
  for (final word in line.words.reversed) {
    final matches = laxPricePattern.allMatches(word.text).toList().reversed;
    for (final match in matches) {
      candidates.add(
        PricedWord(double.parse(match.group(1)!.replaceAll(',', '.')), word),
      );
    }
  }
  final junk = _trailingJunkPrice(line) ?? _splitPrice(line);
  if (junk != null) candidates.add(junk);
  return _distinctAmounts(candidates);
}

List<PricedWord> _distinctAmounts(List<PricedWord> candidates) {
  final seen = <int>{};
  final distinct = <PricedWord>[];
  for (final candidate in candidates) {
    if (seen.add((candidate.price * 100).round())) distinct.add(candidate);
  }
  return distinct;
}

final RegExp _trailingJunkPricePattern = RegExp(r'^(-?\d{1,4}[.,]\d{2})\S$');

PricedWord? _trailingJunkPrice(PhysicalLine line) {
  for (final word in line.words.reversed) {
    final junk = _trailingJunkPricePattern.firstMatch(word.text);
    if (junk != null) {
      return PricedWord(
        double.parse(junk.group(1)!.replaceAll(',', '.')),
        word,
      );
    }
  }
  return null;
}

PricedWord? _splitPrice(PhysicalLine line) {
  final words = line.words;
  if (words.length < 2) return null;
  final units = words[words.length - 2];
  final decimals = words[words.length - 1];
  if (!_integerPattern.hasMatch(units.text) ||
      !_decimalsPattern.hasMatch(decimals.text)) {
    return null;
  }
  final gap = decimals.left - units.right;
  if (gap > (units.bottom - units.top) * 1.5) return null;
  final value = double.parse(
    '${units.text}.${_stripLeading(decimals.text, '.,')}',
  );
  return PricedWord(value, decimals);
}

String foldAccents(String text) {
  final buffer = StringBuffer();
  for (final char in text.split('')) {
    buffer.write(accentFold[char] ?? char);
  }
  return buffer.toString();
}

final RegExp _whitespacePattern = RegExp(r'\s+');

int levenshtein(String left, String right) {
  var previous = List<int>.generate(right.length + 1, (i) => i);
  for (var row = 1; row <= left.length; row++) {
    final current = <int>[row];
    for (var column = 1; column <= right.length; column++) {
      final substitution = left[row - 1] == right[column - 1] ? 0 : 1;
      current.add(
        math.min(
          math.min(previous[column] + 1, current[column - 1] + 1),
          previous[column - 1] + substitution,
        ),
      );
    }
    previous = current;
  }
  return previous.last;
}

bool hasDatePattern(String compact) =>
    _datePattern.hasMatch(compact) || _literalDatePattern.hasMatch(compact);

bool containsTotal(String text) {
  if (containsEntry(text, totalWords)) return true;
  return text
      .split(_whitespacePattern)
      .any(
        (token) =>
            token.length >= fuzzyTotalMinTokenLength &&
            token.length <= fuzzyTotalMaxTokenLength &&
            levenshtein(token.toUpperCase(), fuzzyTotalWord) <=
                fuzzyTotalMaxDistance,
      );
}

bool containsEntry(String text, List<String> lexicon) {
  final upper = foldAccents(text.toUpperCase());
  final compact = upper.replaceAll(_whitespacePattern, '');
  final undotted = upper.replaceAll('.', '');
  final unglyphed = upper
      .replaceAll('0', 'O')
      .replaceAll('1', 'I')
      .replaceAll('5', 'S')
      .replaceAll(_whitespacePattern, '');
  for (final entry in lexicon) {
    final stripped = entry.trim();
    if (stripped.length < 5) {
      final escaped = RegExp.escape(stripped);
      if (RegExp('(?<![A-Z0-9])$escaped(?![A-Z0-9])').hasMatch(upper)) {
        return true;
      }
      if (RegExp('(?<![A-Z])$escaped(?![A-Z])').hasMatch(undotted)) {
        return true;
      }
      continue;
    }
    final boundary = RegExp('(?<![A-Z])${RegExp.escape(entry)}(?![A-Z])');
    if (boundary.hasMatch(upper)) return true;
    if (upper.contains(entry)) continue;
    final squeezed = entry.replaceAll(' ', '');
    if (compact.contains(squeezed) || unglyphed.contains(squeezed)) {
      return true;
    }
  }
  return false;
}

double? _priceColumnLeft(List<PhysicalLine> lines) {
  final rights = <double>[];
  for (final line in lines) {
    final priced = rightmostPrice(line);
    if (priced != null) rights.add(priced.word.right);
  }
  if (rights.isEmpty) return null;
  rights.sort();
  final medianRight = rights[rights.length ~/ 2];
  return medianRight * 0.75;
}

const double labelColumnQuantile = 0.20;

double? labelColumnLeft(List<PhysicalLine> merged) {
  final lefts = <double>[];
  for (final line in merged) {
    final priced = rightmostPrice(line);
    if (priced != null) lefts.add(priced.word.left);
  }
  if (lefts.isEmpty) return null;
  lefts.sort();
  return lefts[(lefts.length * labelColumnQuantile).floor()];
}

String labelZone(PhysicalLine line, double? column) {
  if (column == null) return line.text;
  return line.words
      .where((word) => word.left < column)
      .map((word) => word.text)
      .join(' ');
}

final RegExp _compactLabelPattern = RegExp(r'EUR|€|\s+');

ExtractedReceipt extract(List<PhysicalLine> lines) {
  final store = lines.isEmpty ? null : lines.first.text;
  final date = findDate(lines);
  final columnLeft = _priceColumnLeft(lines);
  final merged = [for (final line in lines) mergePriceFragments(line)];
  final labelColumn = labelColumnLeft(merged);
  final (totalIndex, total) = _findFinalTotal(merged);

  final items = <ExtractedItem>[];
  String? pendingLabel;
  double? subtotal;
  double? payment;

  for (var index = 0; index < merged.length; index++) {
    final line = merged[index];
    final text = line.text;
    final priced = rightmostPrice(line);

    if (containsEntry(text, subtotalWords) && priced != null) {
      subtotal ??= priced.price;
      pendingLabel = null;
      continue;
    }

    if (containsTotal(text)) {
      pendingLabel = null;
      continue;
    }

    if (containsEntry(text, stopWords)) {
      if (payment == null &&
          priced != null &&
          containsEntry(text, paymentWords)) {
        payment = priced.price;
      }
      pendingLabel = null;
      continue;
    }

    if (totalIndex != null && index > totalIndex) continue;

    if (priced == null) {
      pendingLabel = plausibleLabel(text);
      continue;
    }

    if (columnLeft != null && priced.word.right < columnLeft) {
      pendingLabel = plausibleLabel(text);
      continue;
    }
    if (priced.price == 0) {
      pendingLabel = null;
      continue;
    }

    final label = labelZone(line, labelColumn).trim();

    if (priced.price < 0 || _isDiscountLine(label)) {
      if (items.isNotEmpty) {
        items.last.discount = roundCents(
          items.last.discount + priced.price.abs(),
        );
      }
      pendingLabel = null;
      continue;
    }

    final compactLabel = label.replaceAll(_compactLabelPattern, '');
    final quantityMatch =
        quantityPattern.hasMatch(compactLabel) ||
        weightPattern.hasMatch(compactLabel);
    if (quantityMatch && pendingLabel != null) {
      items.add(
        ExtractedItem(
          name: cleanName(pendingLabel),
          amount: priced.price,
          discount: 0.0,
          lineIndex: index,
        ),
      );
      pendingLabel = null;
      continue;
    }

    if (plausibleLabel(label) == null) {
      if (pendingLabel != null && isDetailLine(label)) {
        items.add(
          ExtractedItem(
            name: cleanName(pendingLabel),
            amount: priced.price,
            discount: 0.0,
            lineIndex: index,
          ),
        );
      }
      pendingLabel = null;
      continue;
    }

    items.add(
      ExtractedItem(
        name: cleanName(label),
        amount: priced.price,
        discount: 0.0,
        lineIndex: index,
      ),
    );
    pendingLabel = null;
  }

  return ExtractedReceipt(
    store: store,
    date: date,
    total: total,
    subtotal: subtotal,
    payment: payment,
    items: items,
    tvaTtcSum: _tvaTtcSum(merged),
    printedCount: printedCount(merged),
    fallbackReferences: _fallbackReferences(merged),
  );
}

bool _isExcludedTotalLine(String text) =>
    containsEntry(text, excludedTotalWords) &&
    !containsEntry(text, taxInclusiveWords);

List<double> _linePrices(PhysicalLine line) => [
  for (final word in line.words) ?parsePrice(word.text),
];

List<double> _fallbackReferences(List<PhysicalLine> merged) {
  final candidates = <double>[];
  for (final line in merged) {
    final text = line.text;
    if (containsTotal(text) && !_isExcludedTotalLine(text)) {
      if (rightmostPrice(line) == null && _embeddedPrice(text) == null) {
        final match = _missingSeparatorTotalPattern.firstMatch(text);
        if (match != null) {
          candidates.add(roundCents(int.parse(match.group(1)!) / 100));
        }
      }
      continue;
    }
    if (_countLetters(text) >= 2) continue;
    final prices = _linePrices(line);
    if (prices.length == 1 && prices.first > 0) candidates.add(prices.first);
  }
  return candidates;
}

double? _tvaTtcSum(List<PhysicalLine> merged) {
  var total = 0.0;
  var rows = 0;
  for (final line in merged) {
    if (!containsEntry(line.text, tvaWords)) continue;
    final prices = _linePrices(line);
    if (prices.length >= 3) {
      total += prices.last;
      rows++;
    }
  }
  return rows > 0 ? roundCents(total) : null;
}

int? printedCount(List<PhysicalLine> merged) {
  for (final line in merged) {
    final compact = line.text.toUpperCase().replaceAll(_whitespacePattern, '');
    final match = _articleCountPattern.firstMatch(compact);
    if (match != null) return int.parse(match.group(1)!);
  }
  return null;
}

(int?, double?) _findFinalTotal(List<PhysicalLine> merged) {
  int? totalIndex;
  double? total;
  for (var index = 0; index < merged.length; index++) {
    final line = merged[index];
    if (!containsTotal(line.text) || containsEntry(line.text, subtotalWords)) {
      continue;
    }
    if (_isExcludedTotalLine(line.text)) continue;
    final priced = rightmostPrice(line);
    final price = priced?.price ?? _embeddedPrice(line.text);
    if (price != null) {
      totalIndex = index;
      total = price;
    }
  }
  return (totalIndex, total);
}

final RegExp _embeddedPricePattern = RegExp(r'(\d{1,4}[.,]\d{2})\s*€?\s*$');

double? _embeddedPrice(String text) {
  final match = _embeddedPricePattern.firstMatch(text);
  if (match == null) return null;
  return double.parse(match.group(1)!.replaceAll(',', '.'));
}

final RegExp _detailTokenPattern = RegExp(
  r'^[\d.,()xX*/€%-]*(?:kg|KG|Kg|EUR|[A-Za-z])?$',
);

bool isDetailLine(String label) {
  final stripped = label.trim();
  if (stripped.isEmpty) return true;
  if (_countLetters(stripped) > 3) return false;
  return stripped.split(_whitespacePattern).every(_detailTokenPattern.hasMatch);
}

bool _isDiscountLine(String label) {
  final upper = label.trim().toUpperCase();
  return discountWords.any(upper.startsWith);
}

final RegExp _quantityPrefixPattern = RegExp(r'^\d{1,2}\s?(?=[A-Za-zÀ-ÿ])');
final RegExp _leaderRunPattern = RegExp(r'[.…]{2,}');
final RegExp _trailingPricePattern = RegExp(r'\s?-?\d{1,4}[.,]\d{2}[€eE]?$');
final RegExp _trailingEuroPattern = RegExp(r'\s+[€eE]$');
final RegExp _multiSpacePattern = RegExp(r'\s{2,}');

String cleanName(String label) {
  var cleaned = label.trim().replaceFirst(_quantityPrefixPattern, '');
  cleaned = cleaned.replaceAll(_leaderRunPattern, ' ');
  cleaned = cleaned.replaceFirst(_trailingPricePattern, '');
  cleaned = cleaned.replaceFirst(_trailingEuroPattern, '');
  return cleaned.replaceAll(_multiSpacePattern, ' ').trim();
}

String? plausibleLabel(String text) {
  final stripped = text.trim();
  if (_countLetters(stripped) < 2) return null;
  if (containsEntry(stripped, stopWords)) return null;
  return stripped;
}

String _yearOf(String digits) {
  var read = digits;
  if (read.length == 4) {
    final year = int.parse(read);
    if (year >= _minYear && year <= _maxYear) return read;
    read = read.substring(0, 2);
  }
  final century = int.parse(read) < _centuryPivot ? 2000 : 1900;
  return '${century + int.parse(read)}';
}

bool _isCalendarDay(String day, String month) {
  final d = int.parse(day);
  final m = int.parse(month);
  return d >= 1 && d <= _maxDay && m >= 1 && m <= _maxMonth;
}

String? _monthNumber(String name) {
  final upper = name.toUpperCase();
  for (var index = 0; index < _monthNames.length; index++) {
    for (final entry in _monthNames[index].split('|')) {
      if (upper.startsWith(entry)) return (index + 1).toString().padLeft(2, '0');
    }
  }
  return null;
}

String? _numericDate(String text, [RegExp? pattern]) {
  final digitsOnly = text.replaceAll('o', '0').replaceAll('O', '0');
  for (final match in (pattern ?? _datePattern).allMatches(digitsOnly)) {
    final day = match.group(1)!;
    final month = match.group(2)!;
    if (_isCalendarDay(day, month)) {
      final paddedDay = int.parse(day).toString().padLeft(2, '0');
      final paddedMonth = int.parse(month).toString().padLeft(2, '0');
      return '${_yearOf(match.group(3)!)}-$paddedMonth-$paddedDay';
    }
  }
  return null;
}

String? _literalDate(String compact) {
  final unaccented = foldAccents(compact);
  for (final match in _literalDatePattern.allMatches(unaccented)) {
    final day = match.group(1)!;
    final month = _monthNumber(match.group(2)!);
    if (month != null && _isCalendarDay(day, month)) {
      final paddedDay = int.parse(day).toString().padLeft(2, '0');
      return '${_yearOf(match.group(3)!)}-$month-$paddedDay';
    }
  }
  return null;
}

String? _damagedMonthNumber(String word) {
  final upper = word.toUpperCase();
  if (upper.length < _damagedMonthMinLength) return null;
  final tolerance = upper.length >= _damagedMonthLongLength ? 2 : 1;
  final close = <int>[
    for (var index = 0; index < _fullMonthNames.length; index++)
      if (levenshtein(upper, _fullMonthNames[index]) <= tolerance) index + 1,
  ];
  if (close.length != 1) return null;
  return close.single.toString().padLeft(2, '0');
}

String? _damagedLiteralDate(String text) {
  final unaccented = foldAccents(text);
  for (final match in _damagedLiteralDatePattern.allMatches(unaccented)) {
    final day = match.group(1)!;
    final month = _damagedMonthNumber(match.group(2)!);
    if (month != null && _isCalendarDay(day, month)) {
      final paddedDay = int.parse(day).toString().padLeft(2, '0');
      return '${_yearOf(match.group(3)!)}-$month-$paddedDay';
    }
  }
  return null;
}

String? _dateIn(String text) {
  final spaced = text
      .replaceAll(_whitespacePattern, ' ')
      .replaceAll(_phonePattern, ' ')
      .trim();
  final compact = text
      .replaceAll(_whitespacePattern, '')
      .replaceAll(_phonePattern, ' ');
  return _numericDate(spaced, _boundedDatePattern) ??
      _literalDate(spaced) ??
      _damagedLiteralDate(spaced) ??
      _numericDate(spaced, _spacedDatePattern) ??
      _numericDate(compact) ??
      _literalDate(compact);
}

String? findDate(List<PhysicalLine> lines) {
  for (final line in lines) {
    final found = _dateIn(line.text);
    if (found != null) return found;
  }
  return null;
}
