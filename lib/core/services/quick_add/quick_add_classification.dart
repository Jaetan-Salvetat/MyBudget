import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';

class QuickAddClassification {
  final TransactionType type;
  final TaxonomyNode category;
  final Frequency frequency;

  final DateTime date;

  final bool hasWrittenDate;

  final double? amount;
  final String name;
  final double typeConfidence;
  final double categoryConfidence;
  final double recurrenceConfidence;
  final List<String> categorySuggestions;

  final String cleanedText;

  const QuickAddClassification({
    required this.type,
    required this.category,
    required this.frequency,
    required this.date,
    this.hasWrittenDate = false,
    this.amount,
    required this.name,
    required this.typeConfidence,
    required this.categoryConfidence,
    required this.recurrenceConfidence,
    required this.cleanedText,
    this.categorySuggestions = const [],
  });

  String get categorySlug => category.slug;
}
