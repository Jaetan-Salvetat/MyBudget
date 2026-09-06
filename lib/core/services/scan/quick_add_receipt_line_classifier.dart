import 'package:mybudget/core/services/quick_add/quick_add_classifier_service.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

class QuickAddReceiptLineClassifier implements ReceiptLineClassifier {
  const QuickAddReceiptLineClassifier(this._service);
  final QuickAddClassifierService _service;

  @override
  Future<LinePrediction> classify(String normalizedLine) {
    return _service.categoryOf(normalizedLine);
  }
}
