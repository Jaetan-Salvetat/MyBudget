/// Features par mot, pour décider quels mots d'une ligne forment le libellé.
///
/// `line_features_all.dart` décrit une ligne entière : il sait dire qu'une
/// ligne est un article, jamais où le nom de cet article commence. Or c'est
/// là que se concentrent les libellés faux — un code article collé devant,
/// une quantité ou un prix unitaire collés derrière, sur la bonne ligne.
///
/// Les règles répondaient par une coupe verticale unique. Un ticket imprime
/// trois à cinq colonnes et leurs frontières changent d'une enseigne à
/// l'autre : la colonne devient donc une feature par mot. Un mot dont la
/// bande verticale est occupée, sur les autres lignes, par des nombres
/// appartient à une colonne ; le même mot ailleurs appartient au nom.
///
/// Miroir exact de `ml/scan/research/reference/word_features.py` ; toute
/// divergence décale les colonnes et le modèle décide autrement que la
/// référence. `bench/roles_parity.py` vérifie l'égalité mot à mot.
library;

import 'dart:math' as math;

import 'line_features.dart';
import 'lines.dart';
import 'structure.dart';

const double wordNeighbourAbsent = -1.0;

/// Unités imprimées à côté d'une quantité ou d'un prix au kilo : elles
/// bornent le libellé sans en faire partie.
final RegExp _unitPattern = RegExp(
  r'^(KG|G|GR|L|CL|ML|PCE|PC|U|UN|EUR|€)$',
  caseSensitive: false,
);
final RegExp _countPattern = RegExp(r'^\d{1,3}\s?[xX*]$|^[xX*]\s?\d{1,3}$');
final RegExp _wordCurrency = RegExp(r'[€$]|\bEUR\b', caseSensitive: false);
final RegExp _wordDigit = RegExp(r'\p{Nd}', unicode: true);
final RegExp _wordLetter = RegExp(r'\p{L}', unicode: true);
final RegExp _wordUpper = RegExp(r'\p{Lu}', unicode: true);
final RegExp _allDigits = RegExp(r'^\p{Nd}+$', unicode: true);
final RegExp _currencyStrip = RegExp(r'€|EUR');

/// Trigrammes du mot, chiffres masqués : ce que le mot *dit*, quand sa forme
/// et sa position ne suffisent pas — « TVA », « kg », « REMISE ».
const int wordTrigramBuckets = 16;

final List<String> wordFeatureNames = [
  'left_ratio', 'right_ratio', 'width_ratio', 'height_ratio',
  'word_index_ratio', 'is_first', 'is_last', 'word_count',
  'gap_before', 'gap_after', 'line_position',
  'char_count', 'digit_ratio', 'alpha_ratio', 'upper_ratio',
  'is_pure_digits', 'is_price_shaped', 'is_count', 'is_unit',
  'has_currency', 'confidence',
  'is_price_word', 'after_price', 'dist_to_price',
  'band_fill', 'band_digit_ratio', 'band_alpha_ratio', 'band_price_ratio',
  'line_has_price', 'line_digit_ratio', 'line_word_count_ratio',
  ...[for (var b = 0; b < wordTrigramBuckets; b++) 'tri_$b'],
];

class _Shape {
  const _Shape(this.digitRatio, this.alphaRatio, this.upperRatio);

  final double digitRatio;
  final double alphaRatio;
  final double upperRatio;
}

_Shape _shapeOf(String text) {
  final chars = text.length;
  if (chars == 0) return const _Shape(0.0, 0.0, 0.0);
  return _Shape(
    _wordDigit.allMatches(text).length / chars,
    _wordLetter.allMatches(text).length / chars,
    _wordUpper.allMatches(text).length / chars,
  );
}

bool _isPriceShaped(String text) =>
    pricePattern.hasMatch(text.replaceAll(_currencyStrip, '').trim());

/// Les mots que les *autres* lignes impriment à cette abscisse.
List<Word> _bandWords(List<PhysicalLine> lines, int row, double centre) {
  final found = <Word>[];
  for (var index = 0; index < lines.length; index++) {
    if (index == row) continue;
    for (final word in lines[index].words) {
      if (word.left <= centre && centre <= word.right) {
        found.add(word);
        break;
      }
    }
  }
  return found;
}

/// Le mot qui porte le prix de la ligne, fragments recollés.
Word? _priceWord(PhysicalLine line) =>
    rightmostPrice(mergePriceFragments(line))?.word;

/// Un vecteur de features par mot, ligne par ligne, dans l'ordre du ticket.
List<List<List<double>>> featurizeWords(List<PhysicalLine> lines) {
  if (lines.isEmpty) return const [];
  final words = [for (final line in lines) ...line.words];
  if (words.isEmpty) return [for (final _ in lines) const <List<double>>[]];
  final left = words.map((word) => word.left).reduce(math.min);
  final rightMost = words.map((word) => word.right).reduce(math.max);
  final width = (rightMost - left) == 0 ? 1.0 : rightMost - left;
  final heights = [for (final word in words) word.bottom - word.top]..sort();
  final medianHeightRaw = heights[heights.length ~/ 2];
  final medianHeight = medianHeightRaw == 0 ? 1.0 : medianHeightRaw;
  var maxWords = 0;
  for (final line in lines) {
    if (line.words.length > maxWords) maxWords = line.words.length;
  }
  if (maxWords == 0) maxWords = 1;
  final priceWords = [for (final line in lines) _priceWord(line)];

  final rows = <List<List<double>>>[];
  for (var row = 0; row < lines.length; row++) {
    final line = lines[row];
    final price = priceWords[row];
    final lineDigits = _shapeOf(line.text).digitRatio;
    final lineLeft = line.words.isEmpty
        ? left
        : line.words.map((word) => word.left).reduce(math.min);
    final lineRightRaw = line.words.isEmpty
        ? left + width
        : line.words.map((word) => word.right).reduce(math.max);
    final lineWidth = (lineRightRaw - lineLeft) == 0
        ? 1.0
        : lineRightRaw - lineLeft;
    final vectors = <List<double>>[];
    for (var position = 0; position < line.words.length; position++) {
      final word = line.words[position];
      final shape = _shapeOf(word.text);
      final centre = (word.left + word.right) / 2;
      final band = _bandWords(lines, row, centre);
      final previous = position > 0 ? line.words[position - 1] : null;
      final following = position + 1 < line.words.length
          ? line.words[position + 1]
          : null;
      var bandDigits = 0.0;
      var bandAlpha = 0.0;
      var bandPrices = 0.0;
      for (final other in band) {
        final otherShape = _shapeOf(other.text);
        bandDigits += otherShape.digitRatio;
        bandAlpha += otherShape.alphaRatio;
        if (_isPriceShaped(other.text)) bandPrices += 1.0;
      }
      vectors.add([
        (word.left - left) / width,
        (word.right - left) / width,
        (word.right - word.left) / width,
        (word.bottom - word.top) / medianHeight,
        position / line.words.length,
        position == 0 ? 1.0 : 0.0,
        position == line.words.length - 1 ? 1.0 : 0.0,
        line.words.length.toDouble(),
        previous == null
            ? wordNeighbourAbsent
            : (word.left - previous.right) / width,
        following == null
            ? wordNeighbourAbsent
            : (following.left - word.right) / width,
        (word.left - lineLeft) / lineWidth,
        word.text.length.toDouble(),
        shape.digitRatio,
        shape.alphaRatio,
        shape.upperRatio,
        _allDigits.hasMatch(word.text) ? 1.0 : 0.0,
        _isPriceShaped(word.text) ? 1.0 : 0.0,
        _countPattern.hasMatch(word.text) ||
                quantityPattern.hasMatch(word.text) ||
                weightPattern.hasMatch(word.text)
            ? 1.0
            : 0.0,
        _unitPattern.hasMatch(word.text) ? 1.0 : 0.0,
        _wordCurrency.hasMatch(word.text) ? 1.0 : 0.0,
        word.confidence ?? wordNeighbourAbsent,
        price != null && word.left < price.right && word.right > price.left
            ? 1.0
            : 0.0,
        price != null && word.left >= price.right ? 1.0 : 0.0,
        price == null
            ? wordNeighbourAbsent
            : (price.left - word.right) / width,
        lines.length > 1 ? band.length / (lines.length - 1) : 0.0,
        band.isEmpty ? 0.0 : bandDigits / band.length,
        band.isEmpty ? 0.0 : bandAlpha / band.length,
        band.isEmpty ? 0.0 : bandPrices / band.length,
        price != null ? 1.0 : 0.0,
        lineDigits,
        line.words.length / maxWords,
        ...hashedTrigrams(word.text, wordTrigramBuckets),
      ]);
    }
    rows.add(vectors);
  }
  return rows;
}
