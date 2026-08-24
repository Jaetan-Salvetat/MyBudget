/// Inférence pure Dart du classifieur de lignes (HistGradientBoosting
/// exporté par `analysis/export_line_classifier.py`).
///
/// Score brut par classe = baseline + Σ valeur de la feuille atteinte dans
/// chaque arbre de l'itération ; probabilités par softmax. Aucune
/// dépendance native : le modèle est un JSON embarqué.
library;

import 'dart:math' as math;
import 'dart:typed_data';

const int labelItem = 0;
const int labelDiscount = 1;
const int labelTotal = 2;
const int labelPayment = 3;
const int labelIgnore = 4;

class _Tree {
  _Tree({
    required this.feature,
    required this.threshold,
    required this.left,
    required this.right,
    required this.value,
    required this.missingGoesLeft,
    required this.isLeaf,
  });

  factory _Tree.fromJson(List<dynamic> nodes) {
    final count = nodes.length;
    final tree = _Tree(
      feature: Int32List(count),
      threshold: Float64List(count),
      left: Int32List(count),
      right: Int32List(count),
      value: Float64List(count),
      missingGoesLeft: Uint8List(count),
      isLeaf: Uint8List(count),
    );
    for (var i = 0; i < count; i++) {
      final node = nodes[i] as List<dynamic>;
      tree.feature[i] = node[0] as int;
      tree.threshold[i] = (node[1] as num).toDouble();
      tree.left[i] = node[2] as int;
      tree.right[i] = node[3] as int;
      tree.value[i] = (node[4] as num).toDouble();
      tree.missingGoesLeft[i] = node[5] as int;
      tree.isLeaf[i] = node[6] as int;
    }
    return tree;
  }

  final Int32List feature;
  final Float64List threshold;
  final Int32List left;
  final Int32List right;
  final Float64List value;
  final Uint8List missingGoesLeft;
  final Uint8List isLeaf;

  double leafValue(List<double> features) {
    var index = 0;
    while (isLeaf[index] == 0) {
      final x = features[feature[index]];
      if (x.isNaN) {
        index = missingGoesLeft[index] == 1 ? left[index] : right[index];
      } else {
        index = x <= threshold[index] ? left[index] : right[index];
      }
    }
    return value[index];
  }
}

class LineClassifier {
  LineClassifier._(
    this.version,
    this.featureCount,
    this._baseline,
    this._iterations,
  );

  factory LineClassifier.fromJson(Map<String, dynamic> json) {
    final baseline = [
      for (final value in json['baseline'] as List<dynamic>)
        (value as num).toDouble(),
    ];
    final iterations = [
      for (final trees in json['iterations'] as List<dynamic>)
        [
          for (final nodes in trees as List<dynamic>)
            _Tree.fromJson(nodes as List<dynamic>),
        ],
    ];
    return LineClassifier._(
      json['version'] as String,
      (json['featureNames'] as List<dynamic>).length,
      baseline,
      iterations,
    );
  }

  final String version;
  final int featureCount;
  final List<double> _baseline;
  final List<List<_Tree>> _iterations;

  int get classCount => _baseline.length;

  List<double> rawScores(List<double> features) {
    final raw = [..._baseline];
    for (final trees in _iterations) {
      for (var classIndex = 0; classIndex < trees.length; classIndex++) {
        raw[classIndex] += trees[classIndex].leafValue(features);
      }
    }
    return raw;
  }

  List<double> predictProba(List<double> features) {
    final raw = rawScores(features);
    final peak = raw.reduce(math.max);
    final weights = [for (final value in raw) math.exp(value - peak)];
    final total = weights.fold(0.0, (sum, weight) => sum + weight);
    return [for (final weight in weights) weight / total];
  }

  List<List<double>> predictProbaAll(List<List<double>> rows) =>
      [for (final row in rows) predictProba(row)];
}

/// Indice de la probabilité maximale, première occurrence en cas d'égalité
/// (convention numpy `argmax`).
int argmax(List<double> values) {
  var best = 0;
  for (var index = 1; index < values.length; index++) {
    if (values[index] > values[best]) best = index;
  }
  return best;
}
