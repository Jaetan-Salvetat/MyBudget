/// Features par ligne porteuse de prix, pour le classifieur de lignes.
///
/// Portage de référence de `line_features.py` (V2, 32 features) et
/// `line_features_v3.py` (arithmétique, lexiques flous, trigrammes hachés,
/// contexte des lignes à prix voisines). Le vecteur doit être identique bit
/// à bit à la version Python : c'est lui qui alimente les arbres exportés.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'lines.dart';
import 'structure.dart';

const double _priceCap = 500.0;
const List<double> taxRates = [0.021, 0.055, 0.10, 0.20];
const int taxToleranceCents = 1;
const int fuzzyMinEntryLength = 3;
const int fuzzyMinTokenLength = 3;
const int hashBuckets = 64;
const double priceRatioClip = 3.0;
const int featureCount = 32 + 19 + hashBuckets;

final RegExp _barcodePattern = RegExp(r'\b\d{8,14}\b');
final RegExp _compactLabelPattern = RegExp(r'EUR|€|\s+');
final RegExp _nonLetterRun = RegExp(r'[^A-Z]+');
final RegExp _digitPattern = RegExp(r'\d');
final RegExp _whitespaceRun = RegExp(r'\s+');
final RegExp _letterPattern = RegExp(r'\p{L}', unicode: true);
final RegExp _asciiDigitPattern = RegExp(r'[0-9]');

/// Une ligne fusionnée porteuse d'un prix, prête à featurer.
class PricedLine {
  const PricedLine({
    required this.index,
    required this.line,
    required this.price,
    required this.word,
  });

  final int index;
  final PhysicalLine line;
  final double price;
  final Word word;

  String get label => line.words
      .where((candidate) => !identical(candidate, word))
      .map((candidate) => candidate.text)
      .join(' ')
      .trim();
}

List<PricedLine> pricedLines(List<PhysicalLine> merged) {
  return [
    for (final (index, line) in merged.indexed)
      if (rightmostPrice(line) case final priced?)
        PricedLine(
          index: index,
          line: line,
          price: priced.price,
          word: priced.word,
        ),
  ];
}

double _pageWidth(List<PhysicalLine> merged) {
  var width = double.negativeInfinity;
  for (final line in merged) {
    for (final word in line.words) {
      width = math.max(width, word.right);
    }
  }
  return width == double.negativeInfinity ? 1.0 : width;
}

int _lastTotalIndex(List<PhysicalLine> merged) {
  var last = -1;
  for (final (index, line) in merged.indexed) {
    if (containsEntry(line.text, totalWords)) last = index;
  }
  return last;
}

int _countLetters(String text) => _letterPattern.allMatches(text).length;

int _countDigits(String text) => _asciiDigitPattern.allMatches(text).length;

bool _startsWithDiscountWord(String text) {
  final upper = text.trim().toUpperCase();
  return discountWords.any(upper.startsWith);
}

bool _isNameOnly(PhysicalLine line) {
  if (rightmostPrice(line) != null) return false;
  return _countLetters(line.text) >= 2 &&
      !containsEntry(line.text, stopWords);
}

double _flag(PhysicalLine? line, bool Function(PhysicalLine) predicate) {
  if (line == null) return 0.0;
  return predicate(line) ? 1.0 : 0.0;
}

double _bit(bool value) => value ? 1.0 : 0.0;

List<double> _baseRow(
  List<PhysicalLine> merged,
  List<PricedLine> lines,
  int rank,
  double width,
  int totalIndex,
  double maxPrice,
) {
  final priced = lines[rank];
  final line = priced.line;
  final price = priced.price;
  final word = priced.word;
  final text = line.text;
  final label = priced.label;
  final compactLabel = label.replaceAll(_compactLabelPattern, '');
  final prevLine = priced.index > 0 ? merged[priced.index - 1] : null;
  final nextLine =
      priced.index + 1 < merged.length ? merged[priced.index + 1] : null;
  final pricesInLine = [
    for (final candidate in line.words) ?parsePrice(candidate.text),
  ];
  return [
    math.min(price.abs(), _priceCap),
    _bit(price < 0),
    _bit((price * 100).abs() % 10 < 0.5),
    word.right / width,
    word.left / width,
    priced.index / math.max(merged.length - 1, 1),
    pricesInLine.length.toDouble(),
    line.words.length.toDouble(),
    _countLetters(text).toDouble(),
    _countDigits(text).toDouble(),
    _countLetters(label).toDouble(),
    _bit(label.contains('%')),
    _bit(isDetailLine(label)),
    _bit(quantityPattern.hasMatch(compactLabel) ||
        weightPattern.hasMatch(compactLabel)),
    _bit(_barcodePattern.hasMatch(label)),
    _bit(containsEntry(text, totalWords)),
    _bit(containsEntry(text, subtotalWords)),
    _bit(containsEntry(text, discountWords)),
    _bit(containsEntry(text, paymentWords)),
    _bit(containsEntry(text, tvaWords)),
    _bit(containsEntry(text, stopWords)),
    _bit(_startsWithDiscountWord(label)),
    _bit(totalIndex >= 0 && priced.index > totalIndex),
    _bit(rank == lines.length - 1),
    _bit((price.abs() - maxPrice).abs() < 0.005),
    _flag(prevLine, (l) => rightmostPrice(l) != null),
    _flag(prevLine, (l) => containsEntry(l.text, totalWords)),
    _flag(prevLine, (l) => containsEntry(l.text, stopWords)),
    _flag(prevLine, _isNameOnly),
    _flag(nextLine, (l) => rightmostPrice(l) != null),
    _flag(nextLine, (l) => containsEntry(l.text, totalWords)),
    _flag(nextLine, (l) => _startsWithDiscountWord(l.text)),
  ];
}

/// Le prix `index` égale la somme signée d'un bloc contigu d'au moins deux
/// lignes se terminant juste au-dessus de lui.
bool blockSumMatches(List<int> cents, int index) {
  final target = cents[index];
  var running = 0;
  for (var start = index - 1; start >= 0; start--) {
    running += cents[start];
    if (index - start >= 2 && running == target) return true;
  }
  return false;
}

/// Ligne négative égale à la somme d'au moins deux lignes négatives
/// précédentes : récapitulatif « total des avantages », pas une remise.
bool discountSummary(List<int> cents, int index) {
  if (cents[index] >= 0) return false;
  final previous = [
    for (var i = 0; i < index; i++)
      if (cents[i] < 0) cents[i],
  ];
  return previous.length >= 2 &&
      previous.fold(0, (sum, value) => sum + value) == cents[index];
}

/// Le prix est une fraction fiscale d'un autre prix du ticket : montant de
/// TVA (taux × HT ou part TVA d'un TTC) ou base HT d'un TTC.
bool taxShaped(int cents, List<int> allCents) {
  if (cents <= 0) return false;
  for (final other in allCents) {
    if (other <= 0 || other == cents) continue;
    for (final rate in taxRates) {
      final candidates = [
        other * rate,
        other * rate / (1 + rate),
        other / (1 + rate),
      ];
      if (candidates.any((c) => (cents - c).abs() <= taxToleranceCents)) {
        return true;
      }
    }
  }
  return false;
}

String normalizedText(String text) => foldAccents(text.toUpperCase())
    .replaceAll('0', 'O')
    .replaceAll('1', 'I')
    .replaceAll('5', 'S');

int levenshtein(String left, String right) {
  var previous = List<int>.generate(right.length + 1, (i) => i);
  for (var row = 1; row <= left.length; row++) {
    final current = <int>[row];
    for (var column = 1; column <= right.length; column++) {
      final substitution =
          left[row - 1] == right[column - 1] ? 0 : 1;
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

double _similarity(String candidate, String entry) =>
    1.0 - levenshtein(candidate, entry) / math.max(entry.length, 1);

/// Similarité maximale (0..1) entre le texte et le lexique. Les entrées
/// courtes (< 3 caractères) n'acceptent qu'un match exact en frontière de
/// mot, comme dans les règles.
double fuzzyLexiconSimilarity(String text, List<String> lexicon) {
  final normalized = normalizedText(text);
  final tokens = normalized.split(_nonLetterRun).where((t) => t.isNotEmpty);
  final compact = tokens.join();
  var best = 0.0;
  for (final rawEntry in lexicon) {
    final entry = normalizedText(rawEntry).replaceAll(' ', '');
    if (entry.length < fuzzyMinEntryLength) {
      final boundary = RegExp('(?<![A-Z])${RegExp.escape(entry)}(?![A-Z])');
      if (boundary.hasMatch(normalized)) return 1.0;
      continue;
    }
    for (final token in tokens) {
      if (token.length >= fuzzyMinTokenLength) {
        best = math.max(best, _similarity(token, entry));
      }
    }
    final windows = math.max(compact.length - entry.length + 1, 0);
    for (var start = 0; start < windows; start++) {
      final window = compact.substring(start, start + entry.length);
      best = math.max(best, _similarity(window, entry));
    }
    if (best >= 1.0) return 1.0;
  }
  return best;
}

List<int> _crcTable = _buildCrcTable();

List<int> _buildCrcTable() {
  final table = List<int>.filled(256, 0);
  for (var i = 0; i < 256; i++) {
    var crc = i;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) == 1 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
    table[i] = crc;
  }
  return table;
}

/// CRC-32 (IEEE 802.3), identique à `zlib.crc32` côté Python.
int crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final byte in bytes) {
    crc = _crcTable[(crc ^ byte) & 0xFF] ^ (crc >> 8);
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

List<double> hashedTrigrams(String text, int buckets) {
  var folded = normalizedText(text.replaceAll(_digitPattern, '#'));
  folded = folded.replaceAll(_whitespaceRun, ' ').trim();
  final padded = ' $folded ';
  final vector = List<double>.filled(buckets, 0.0);
  for (var start = 0; start < math.max(padded.length - 2, 0); start++) {
    final trigram = padded.substring(start, start + 3);
    vector[crc32(utf8.encode(trigram)) % buckets] = 1.0;
  }
  return vector;
}

double _logRatio(int current, int? other) {
  if (other == null || other <= 0 || current <= 0) return 0.0;
  final ratio = math.log(current / other);
  return math.max(-priceRatioClip, math.min(priceRatioClip, ratio));
}

List<List<double>> _extraRows(List<PricedLine> lines) {
  final cents = [for (final priced in lines) (priced.price * 100).round()];
  final absolute = [for (final c in cents) c.abs()];
  final count = lines.length;
  final sortedDesc = [...absolute]..sort((a, b) => b.compareTo(a));
  final fuzzyTotal = [
    for (final priced in lines)
      fuzzyLexiconSimilarity(priced.line.text, totalWords),
  ];
  final block = [for (var i = 0; i < count; i++) blockSumMatches(cents, i)];
  final rows = <List<double>>[];
  for (var index = 0; index < count; index++) {
    final text = lines[index].line.text;
    final prevIndex = index > 0 ? index - 1 : null;
    final nextIndex = index + 1 < count ? index + 1 : null;
    final duplicates = absolute.where((c) => c == absolute[index]).length - 1;
    rows.add([
      _bit(block[index]),
      _bit(discountSummary(cents, index)),
      _bit(prevIndex != null && cents[prevIndex] == cents[index]),
      math.min(duplicates, 3) / 3.0,
      _bit(taxShaped(cents[index], cents)),
      sortedDesc.indexOf(absolute[index]) / math.max(count - 1, 1),
      index / math.max(count - 1, 1),
      fuzzyLexiconSimilarity(text, totalWords),
      fuzzyLexiconSimilarity(text, subtotalWords),
      fuzzyLexiconSimilarity(text, discountWords),
      fuzzyLexiconSimilarity(text, paymentWords),
      fuzzyLexiconSimilarity(text, tvaWords),
      fuzzyLexiconSimilarity(text, stopWords),
      prevIndex != null ? fuzzyTotal[prevIndex] : 0.0,
      nextIndex != null ? fuzzyTotal[nextIndex] : 0.0,
      _logRatio(absolute[index], prevIndex != null ? absolute[prevIndex] : null),
      _logRatio(absolute[index], nextIndex != null ? absolute[nextIndex] : null),
      _bit(prevIndex != null && block[prevIndex]),
      _bit(nextIndex != null && block[nextIndex]),
      ...hashedTrigrams(lines[index].label, hashBuckets),
    ]);
  }
  return rows;
}

/// Lignes à prix et leur vecteur de features V3, depuis les lignes
/// physiques déjà passées par [mergePriceFragments].
(List<PricedLine>, List<List<double>>) featurize(List<PhysicalLine> merged) {
  final lines = pricedLines(merged);
  if (lines.isEmpty) return (const [], const []);
  final width = _pageWidth(merged);
  final totalIndex = _lastTotalIndex(merged);
  var maxPrice = 0.0;
  for (final priced in lines) {
    maxPrice = math.max(maxPrice, priced.price.abs());
  }
  final extras = _extraRows(lines);
  final rows = [
    for (var rank = 0; rank < lines.length; rank++)
      [
        ..._baseRow(merged, lines, rank, width, totalIndex, maxPrice),
        ...extras[rank],
      ],
  ];
  return (lines, rows);
}

List<PhysicalLine> mergedLines(List<PhysicalLine> rawLines) =>
    [for (final line in rawLines) mergePriceFragments(line)];
