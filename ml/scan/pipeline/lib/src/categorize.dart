library;

import 'normalize.dart';

typedef LinePrediction = ({String slug, double confidence});

abstract interface class ReceiptLineClassifier {
  Future<LinePrediction> classify(String normalizedLine);
}

class ReceiptCategorizer {
  final ReceiptLineClassifier _classifier;

  const ReceiptCategorizer(this._classifier);

  Future<List<LinePrediction>> categorize(List<String> itemNames) async => [
    for (final name in itemNames)
      await _classifier.classify(normalizeReceiptLine(name)),
  ];
}
