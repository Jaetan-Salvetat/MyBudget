/// Structuration par classifieur de lignes et décodage sous contrainte
/// checksum. Portage de référence de `structure_ml.py` et
/// `decode_constrained.py`.
///
/// Le classifieur n'étiquette que les lignes porteuses de prix ; les
/// montants sont recopiés de l'OCR, jamais générés. Le décodeur cherche
/// l'étiquetage le plus probable dont la somme (articles − remises) retombe
/// exactement sur une référence imprimée : subset-sum exact en centimes.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'classifier.dart';
import 'line_features.dart';
import 'lines.dart';
import 'structure.dart';

const int centsCap = 500000;
const int negativeCap = 50000;
const double defaultMinProb = 0.02;
const int defaultMaxReferences = 3;
const double defaultMinReferenceProb = 0.5;
const double _probabilityFloor = 1e-12;
const List<int> labelOrder = [labelItem, labelDiscount, labelIgnore];

class LineOptions {
  const LineOptions({required this.cents, required this.logProbs});

  final int cents;
  final Map<int, double> logProbs;
}

const LineOptions forcedIgnore =
    LineOptions(cents: 0, logProbs: {labelIgnore: 0.0});

int _contribution(int label, int cents) {
  if (label == labelItem) return cents;
  if (label == labelDiscount) return -cents.abs();
  return 0;
}

/// Étiquetage maximisant Σ log P sous contrainte Σ contributions =
/// [targetCents]. Une étiquette dont la probabilité est sous [minProb] est
/// interdite : on ne force jamais un rôle que le modèle juge impossible.
List<int>? bestAssignment(
  List<LineOptions> lines,
  int targetCents, {
  double minProb = 0.0,
}) {
  if (lines.isEmpty) return targetCents == 0 ? [] : null;
  final floor = minProb > 0 ? math.log(minProb) : double.negativeInfinity;
  var positiveReach = 0;
  var negativeReach = 0;
  for (final line in lines) {
    positiveReach += math.max(line.cents, 0);
    negativeReach += line.cents.abs();
  }
  positiveReach = math.min(positiveReach, centsCap);
  negativeReach = math.min(negativeReach, negativeCap);
  final size = positiveReach + negativeReach + 1;
  final offset = negativeReach;
  var scores = Float64List(size)..fillRange(0, size, double.negativeInfinity);
  scores[offset] = 0.0;
  final choices = [
    for (var i = 0; i < lines.length; i++) Int8List(size)..fillRange(0, size, -1),
  ];

  for (final (index, line) in lines.indexed) {
    final next = Float64List(size)..fillRange(0, size, double.negativeInfinity);
    for (final label in labelOrder) {
      final logProb = line.logProbs[label];
      if (logProb == null || logProb < floor) continue;
      final shift = _contribution(label, line.cents);
      if (shift >= 0) {
        for (var position = shift; position < size; position++) {
          final candidate = scores[position - shift] + logProb;
          if (candidate > next[position]) {
            next[position] = candidate;
            choices[index][position] = label;
          }
        }
      } else {
        for (var position = 0; position < size + shift; position++) {
          final candidate = scores[position - shift] + logProb;
          if (candidate > next[position]) {
            next[position] = candidate;
            choices[index][position] = label;
          }
        }
      }
    }
    scores = next;
  }

  var position = targetCents + offset;
  if (position < 0 || position >= size || scores[position].isInfinite) {
    return null;
  }
  final labels = <int>[];
  for (var index = lines.length - 1; index >= 0; index--) {
    final label = choices[index][position];
    labels.add(label);
    position -= _contribution(label, lines[index].cents);
  }
  return labels.reversed.toList();
}

int _toCents(double price) => (price * 100).round();

double _logOf(double probability) =>
    math.log(math.max(probability, _probabilityFloor));

class Hypothesis {
  const Hypothesis({
    required this.referenceRank,
    required this.referenceRole,
    required this.labels,
    required this.logProb,
  });

  final int referenceRank;
  final int referenceRole;
  final List<int> labels;
  final double logProb;
}

/// Options par ligne sous deux invariants de ticket : rien ne compte après
/// la ligne de référence (total ou paiement — la monnaie rendue qui suit un
/// paiement en espèces n'est jamais un article), et un prix négatif n'est
/// jamais un article. Une ligne à 0 centime n'apporte aucune information de
/// somme.
List<LineOptions> lineOptions(
  List<PricedLine> lines,
  List<List<double>> probas,
  int referenceRank, {
  bool argmaxOnly = false,
}) {
  final options = <LineOptions>[];
  for (final (rank, priced) in lines.indexed) {
    if (rank == referenceRank) continue;
    final row = probas[rank];
    final cents = _toCents(priced.price);
    if (cents == 0 || rank > referenceRank) {
      options.add(forcedIgnore);
      continue;
    }
    final skip = math.max(
      row[labelIgnore],
      math.max(row[labelTotal], row[labelPayment]),
    );
    var logProbs = <int, double>{
      labelDiscount: _logOf(row[labelDiscount]),
      labelIgnore: _logOf(skip),
    };
    if (cents > 0) logProbs[labelItem] = _logOf(row[labelItem]);
    if (argmaxOnly) {
      int? bestLabel;
      for (final label in labelOrder) {
        final value = logProbs[label];
        if (value == null) continue;
        if (bestLabel == null || value > logProbs[bestLabel]!) {
          bestLabel = label;
        }
      }
      logProbs = {bestLabel!: logProbs[bestLabel]!};
    }
    options.add(LineOptions(cents: cents, logProbs: logProbs));
  }
  return options;
}

List<int> _referenceCandidates(
  List<List<double>> probas,
  int role,
  int maxReferences,
  double minReferenceProb,
) {
  final ranks = List<int>.generate(probas.length, (i) => i)
    ..sort((a, b) {
      final byProb = probas[b][role].compareTo(probas[a][role]);
      return byProb != 0 ? byProb : a.compareTo(b);
    });
  return [
    for (final rank in ranks)
      if (probas[rank][role] >= minReferenceProb) rank,
  ].take(maxReferences).toList();
}

double _assignmentLogProb(List<int> labels, List<LineOptions> options) {
  var total = 0.0;
  for (final (index, label) in labels.indexed) {
    total += options[index].logProbs[label]!;
  }
  return total;
}

Hypothesis? _bestHypothesis(
  List<PricedLine> lines,
  List<List<double>> probas,
  int role,
  double minProb,
  int maxReferences,
  double minReferenceProb,
  bool argmaxOnly,
) {
  Hypothesis? best;
  for (final rank in _referenceCandidates(
    probas,
    role,
    maxReferences,
    minReferenceProb,
  )) {
    final target = _toCents(lines[rank].price);
    if (target <= 0) continue;
    final options = lineOptions(lines, probas, rank, argmaxOnly: argmaxOnly);
    final labels = bestAssignment(options, target, minProb: minProb);
    if (labels == null) continue;
    final logProb =
        _assignmentLogProb(labels, options) + _logOf(probas[rank][role]);
    if (best == null || logProb > best.logProb) {
      final fullLabels = [...labels]..insert(rank, role);
      best = Hypothesis(
        referenceRank: rank,
        referenceRole: role,
        labels: fullLabels,
        logProb: logProb,
      );
    }
  }
  return best;
}

/// Les totaux d'abord, avec exploration. Un paiement ne sert de référence
/// qu'en dernier recours et sans aucun flip : les articles tels que le
/// modèle les voit doivent tomber pile sur le montant payé — deux signaux
/// indépendants contre un total lu qui ne colle pas.
Hypothesis? decodeConstrained(
  List<PricedLine> lines,
  List<List<double>> probas, {
  double minProb = defaultMinProb,
  int maxReferences = defaultMaxReferences,
  double minReferenceProb = defaultMinReferenceProb,
}) {
  final total = _bestHypothesis(
    lines,
    probas,
    labelTotal,
    minProb,
    maxReferences,
    minReferenceProb,
    false,
  );
  if (total != null) return total;
  return _bestHypothesis(
    lines,
    probas,
    labelPayment,
    minProb,
    maxReferences,
    minReferenceProb,
    true,
  );
}

Map<int, String?> _pendingLabels(
  List<PhysicalLine> merged,
  List<PricedLine> lines,
) {
  final pricedIndexes = {for (final priced in lines) priced.index};
  final pendingByIndex = <int, String?>{};
  String? pending;
  for (final (index, line) in merged.indexed) {
    pendingByIndex[index] = pending;
    pending = pricedIndexes.contains(index) ? null : plausibleLabel(line.text);
  }
  return pendingByIndex;
}

/// Reçu structuré depuis les rôles par ligne. Un prix négatif est toujours
/// une remise, quel que soit son label : un article ne peut pas être
/// négatif.
ExtractedReceipt? receiptFromLabels(
  List<PhysicalLine> merged,
  List<PricedLine> lines,
  List<int> labels,
) {
  final pendingByIndex = _pendingLabels(merged, lines);
  final items = <ExtractedItem>[];
  double? total;
  double? payment;
  for (final (rank, priced) in lines.indexed) {
    var label = labels[rank];
    final price = roundCents(priced.price);
    if (label == labelItem && price < 0) label = labelDiscount;
    if (label == labelItem) {
      final name = plausibleLabel(priced.label) ??
          pendingByIndex[priced.index] ??
          priced.label;
      items.add(
        ExtractedItem(name: cleanName(name), amount: price, discount: 0.0),
      );
    } else if (label == labelDiscount && items.isNotEmpty) {
      items.last.discount = roundCents(items.last.discount + price.abs());
    } else if (label == labelTotal) {
      total = price;
    } else if (label == labelPayment && payment == null) {
      payment = price;
    }
  }
  if (items.isEmpty) return null;
  return ExtractedReceipt(
    store: merged.isEmpty ? null : merged.first.text,
    date: findDate(merged),
    total: total,
    subtotal: null,
    payment: payment,
    items: items,
  );
}

/// Structuration par l'argmax du classifieur.
ExtractedReceipt? extractMl(
  List<PhysicalLine> merged,
  LineClassifier classifier,
) {
  final (lines, rows) = featurize(merged);
  if (lines.isEmpty) return null;
  final labels = [for (final row in rows) argmax(classifier.predictProba(row))];
  return receiptFromLabels(merged, lines, labels);
}

/// Structuration par décodage sous contrainte checksum.
ExtractedReceipt? extractConstrained(
  List<PhysicalLine> merged,
  LineClassifier classifier,
) {
  final (lines, rows) = featurize(merged);
  if (lines.isEmpty) return null;
  final hypothesis = decodeConstrained(
    lines,
    classifier.predictProbaAll(rows),
  );
  if (hypothesis == null) return null;
  return receiptFromLabels(merged, lines, hypothesis.labels);
}
