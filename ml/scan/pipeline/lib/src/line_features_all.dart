/// Features de ligne, pour *toutes* les lignes d'un ticket.
///
/// `line_features.dart` ne décrit que les lignes porteuses de prix : il
/// fallait un prix pour calculer la plupart de ses colonnes. Or l'enseigne,
/// la ligne de date et le libellé d'un article dont le prix est imprimé plus
/// bas vivent sur des lignes sans prix — aucun modèle ne pouvait les
/// apprendre.
///
/// Ces features-ci ne présupposent rien : géométrie relative au ticket, forme
/// du texte, lexiques, et le voisinage immédiat. Miroir exact de
/// `ml/scan/research/reference/line_features_all.py` ; toute divergence
/// décale silencieusement les colonnes et le modèle décide autrement que la
/// référence. `tool/parity.dart` vérifie l'égalité ligne à ligne.
library;

import 'dart:math' as math;

import 'line_features.dart';
import 'lines.dart';
import 'structure.dart';

/// Lexiques propres aux features de ligne. `changeWords` existe aussi dans
/// `invariants.dart` : même contenu, deux usages sans dépendance entre eux.
const List<String> featureChangeWords = ['RENDU', 'RENDRE', 'MONNAIE', 'CHANGE'];
const List<String> featureCountWords = ['ARTICLE', 'ARTICLES', 'NOMBRE', 'QTE'];
const double neighbourAbsent = -1.0;

final RegExp _currency = RegExp(r'[€$]|\bEUR\b');
final RegExp _whitespace = RegExp(r'\s+');
final RegExp _letter = RegExp(r'\p{L}', unicode: true);
final RegExp _digit = RegExp(r'\p{Nd}', unicode: true);
final RegExp _upper = RegExp(r'\p{Lu}', unicode: true);

/// Fenêtre du comptage de densité, de part et d'autre de la ligne.
const int densityWindow = 3;

/// Trigrammes de caractères hachés du texte de la ligne, chiffres masqués.
///
/// Les autres colonnes ne décrivent que la forme et la position : rien n'y dit
/// ce que la ligne *raconte*. Or c'est le contenu qui sépare un nom de produit
/// d'une raison sociale ou d'une mention de pied.
const int trigramBuckets = 64;

final List<String> featureNamesAll = [
  'rank_ratio', 'top_ratio', 'height_ratio', 'width_ratio', 'left_ratio',
  'word_count', 'char_count', 'digit_ratio', 'alpha_ratio', 'upper_ratio',
  'has_price', 'price_log', 'price_right_ratio', 'is_negative',
  'has_date', 'has_currency', 'has_letters_only',
  'is_total', 'is_subtotal', 'is_tva', 'is_payment', 'is_discount',
  'is_change', 'is_count',
  'prev_has_price', 'next_has_price', 'prev_is_total', 'next_is_total',
  'prev_height_ratio', 'next_height_ratio',
  'priced_rank_ratio', 'after_first_total',
  // Où la ligne se situe par rapport à la zone des articles. Sans elles, une
  // ligne sans prix n'a aucune position connue dans cette zone —
  // `priced_rank_ratio` vaut -1 — et rien ne distingue le libellé d'un article
  // d'une ligne d'en-tête.
  'dist_prev_priced', 'dist_next_priced', 'in_priced_span', 'span_position',
  'priced_density', 'next_priced_not_total',
  ...[for (var b = 0; b < trigramBuckets; b++) 'tri_$b'],
];

int _countMatches(String text, RegExp pattern) =>
    pattern.allMatches(text).length;

double _pricedDensity(List<PricedWord?> prices, int index) {
  final from = index - densityWindow < 0 ? 0 : index - densityWindow;
  final to = index + densityWindow + 1 > prices.length
      ? prices.length
      : index + densityWindow + 1;
  var count = 0;
  for (var position = from; position < to; position++) {
    if (prices[position] != null) count++;
  }
  return count / (2 * densityWindow + 1);
}

double _medianHeight(List<PhysicalLine> lines) {
  if (lines.isEmpty) return 1.0;
  final heights = [for (final line in lines) line.bottom - line.top]..sort();
  return heights[heights.length ~/ 2];
}

/// Une ligne de features par ligne physique, dans l'ordre du ticket.
List<List<double>> featurizeAll(List<PhysicalLine> lines) {
  if (lines.isEmpty) return const [];
  final merged = [for (final line in lines) mergePriceFragments(line)];
  final prices = [for (final line in merged) rightmostPrice(line)];
  final medianHeight = _medianHeight(merged) == 0 ? 1.0 : _medianHeight(merged);
  final top = merged.map((line) => line.top).reduce(math.min);
  final bottom = merged.map((line) => line.bottom).reduce(math.max);
  final span = (bottom - top) == 0 ? 1.0 : bottom - top;
  final left = merged
      .expand((line) => line.words)
      .map((word) => word.left)
      .reduce(math.min);
  final right = merged
      .expand((line) => line.words)
      .map((word) => word.right)
      .reduce(math.max);
  final width = (right - left) == 0 ? 1.0 : right - left;
  final totals = [for (final line in merged) containsTotal(line.text)];
  var firstTotal = merged.length;
  for (var i = 0; i < totals.length; i++) {
    if (totals[i]) {
      firstTotal = i;
      break;
    }
  }
  final pricedRanks = <int>[];
  for (var i = 0; i < prices.length; i++) {
    if (prices[i] != null) pricedRanks.add(i);
  }

  double heightRatioAt(int position) =>
      (merged[position].bottom - merged[position].top) / medianHeight;

  final firstPriced = pricedRanks.isEmpty ? null : pricedRanks.first;
  final lastPriced = pricedRanks.isEmpty ? null : pricedRanks.last;
  final pricedSpan = firstPriced == null
      ? 1.0
      : ((lastPriced! - firstPriced) == 0 ? 1.0 : (lastPriced - firstPriced).toDouble());

  double distanceToPriced(int index, int step) {
    var position = index + step;
    while (position >= 0 && position < merged.length) {
      if (prices[position] != null) {
        return (position - index).abs() / merged.length;
      }
      position += step;
    }
    return neighbourAbsent;
  }

  final rows = <List<double>>[];
  for (var index = 0; index < merged.length; index++) {
    final line = merged[index];
    final text = line.text;
    final chars = text.length;
    final digits = _countMatches(text, _digit);
    final alpha = _countMatches(text, _letter);
    final upper = _countMatches(text, _upper);
    final digitRatio = chars == 0 ? 0.0 : digits / chars;
    final alphaRatio = chars == 0 ? 0.0 : alpha / chars;
    final upperRatio = chars == 0 ? 0.0 : upper / chars;
    final price = prices[index];
    final lineLeft = line.words.map((word) => word.left).reduce(math.min);
    final lineRight = line.words.map((word) => word.right).reduce(math.max);
    final compact = text.replaceAll(_whitespace, '');

    double neighbourBool(int offset, bool Function(int) of) {
      final position = index + offset;
      if (position < 0 || position >= merged.length) return neighbourAbsent;
      return of(position) ? 1.0 : 0.0;
    }

    double neighbourHeight(int offset) {
      final position = index + offset;
      if (position < 0 || position >= merged.length) return neighbourAbsent;
      return heightRatioAt(position);
    }

    rows.add([
      index / merged.length,
      (line.top - top) / span,
      heightRatioAt(index),
      (lineRight - lineLeft) / width,
      (lineLeft - left) / width,
      line.words.length.toDouble(),
      chars.toDouble(),
      digitRatio,
      alphaRatio,
      upperRatio,
      price != null ? 1.0 : 0.0,
      price != null ? price.price.abs() : 0.0,
      price != null ? (price.word.right - left) / width : 0.0,
      price != null && price.price < 0 ? 1.0 : 0.0,
      hasDatePattern(compact) ? 1.0 : 0.0,
      _currency.hasMatch(text) ? 1.0 : 0.0,
      alpha > 0 && digitRatio == 0 ? 1.0 : 0.0,
      totals[index] ? 1.0 : 0.0,
      containsEntry(text, subtotalWords) ? 1.0 : 0.0,
      containsEntry(text, tvaWords) ? 1.0 : 0.0,
      containsEntry(text, paymentWords) ? 1.0 : 0.0,
      containsEntry(text, discountWords) ? 1.0 : 0.0,
      containsEntry(text, featureChangeWords) ? 1.0 : 0.0,
      containsEntry(text, featureCountWords) ? 1.0 : 0.0,
      neighbourBool(-1, (p) => prices[p] != null),
      neighbourBool(1, (p) => prices[p] != null),
      neighbourBool(-1, (p) => totals[p]),
      neighbourBool(1, (p) => totals[p]),
      neighbourHeight(-1),
      neighbourHeight(1),
      pricedRanks.contains(index)
          ? pricedRanks.indexOf(index) / pricedRanks.length
          : neighbourAbsent,
      index > firstTotal ? 1.0 : 0.0,
      distanceToPriced(index, -1),
      distanceToPriced(index, 1),
      firstPriced != null && index >= firstPriced && index <= lastPriced!
          ? 1.0
          : 0.0,
      firstPriced != null ? (index - firstPriced) / pricedSpan : neighbourAbsent,
      _pricedDensity(prices, index),
      neighbourBool(1, (p) => prices[p] != null && !totals[p]),
      ...hashedTrigrams(text, trigramBuckets),
    ]);
  }
  return rows;
}
