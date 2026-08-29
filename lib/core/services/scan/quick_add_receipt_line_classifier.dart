import 'package:mybudget/core/services/quick_add/quick_add_classifier_service.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

/// Branche la catégorisation du scan sur le modèle embarqué de l'ajout
/// rapide : une seule session ONNX pour les deux fonctions.
class QuickAddReceiptLineClassifier implements ReceiptLineClassifier {
  final QuickAddClassifierService _service;

  const QuickAddReceiptLineClassifier(this._service);

  @override
  Future<LinePrediction> classify(String normalizedLine) {
    return _service.categoryOf(normalizedLine);
  }
}
