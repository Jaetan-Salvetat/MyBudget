import 'package:mybudget/core/services/quick_add/quick_add_classification.dart';

abstract interface class QuickAddEngine {
  Future<QuickAddClassification> classify(String input);
}
