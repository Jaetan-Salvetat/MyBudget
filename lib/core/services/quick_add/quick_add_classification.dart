import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';

class QuickAddClassification {
  final TransactionType type;
  final TaxonomyGroup group;
  final String taxonomyCategory;
  final Frequency frequency;
  final double amount;
  final String name;
  final double typeConfidence;
  final double categoryConfidence;
  final double recurrenceConfidence;

  const QuickAddClassification({
    required this.type,
    required this.group,
    required this.taxonomyCategory,
    required this.frequency,
    required this.amount,
    required this.name,
    required this.typeConfidence,
    required this.categoryConfidence,
    required this.recurrenceConfidence,
  });
}
