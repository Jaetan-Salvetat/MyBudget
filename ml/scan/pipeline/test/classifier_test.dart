import 'dart:math' as math;

import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:test/test.dart';

LineClassifier tinyModel() {
  return LineClassifier.fromJson({
    'version': 'test',
    'featureNames': ['x'],
    'classes': [0, 1],
    'baseline': [0.0, 0.0],
    'iterations': [
      [
        [
          [0, 0.5, 1, 2, 0.0, 1, 0],
          [0, 0.0, 0, 0, 1.0, 0, 1],
          [0, 0.0, 0, 0, -1.0, 0, 1],
        ],
        [
          [0, 0.5, 1, 2, 0.0, 1, 0],
          [0, 0.0, 0, 0, -1.0, 0, 1],
          [0, 0.0, 0, 0, 1.0, 0, 1],
        ],
      ],
    ],
  });
}

void main() {
  test('raw scores sum baseline and leaves, threshold is inclusive', () {
    final model = tinyModel();
    expect(model.rawScores([0.5]), [1.0, -1.0]);
    expect(model.rawScores([0.6]), [-1.0, 1.0]);
  });

  test('probabilities are a softmax of raw scores', () {
    final probas = tinyModel().predictProba([0.0]);
    final expected = math.exp(1.0) / (math.exp(1.0) + math.exp(-1.0));
    expect(probas[0], closeTo(expected, 1e-12));
    expect(probas[0] + probas[1], closeTo(1.0, 1e-12));
  });

  test('missing value follows the exported direction', () {
    expect(tinyModel().rawScores([double.nan]), [1.0, -1.0]);
  });

  test('argmax returns first maximum', () {
    expect(argmax([0.2, 0.5, 0.5]), 1);
  });

  test('predict rend l\'étiquette du modèle, pas l\'indice du score', () {
    final model = tinyModel();
    expect(model.predict([0.0]), 0);
    expect(model.predict([1.0]), 1);
  });
}
