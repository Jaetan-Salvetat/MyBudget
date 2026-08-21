import 'package:mybudget/core/enums/transaction_type.dart';

class QuickAddResultModel {
  final TransactionType type;
  final String name;
  final double amount;
  final String? categorySlug;
  final String frequency;
  final double categoryConfidence;
  final List<String> categorySuggestions;

  /// Text a user correction is remembered under.
  final String memoryKey;

  const QuickAddResultModel({
    required this.type,
    required this.name,
    required this.amount,
    required this.frequency,
    this.categorySlug,
    this.categoryConfidence = 1.0,
    this.categorySuggestions = const [],
    this.memoryKey = '',
  });

  /// True when the model was not confident enough to assign a category on its
  /// own: the UI must ask instead of silently picking.
  bool get needsCategoryConfirmation =>
      categoryConfidence < categoryConfidenceThreshold;

  static const double categoryConfidenceThreshold = 0.6;

  QuickAddResultModel copyWith({
    TransactionType? type,
    String? name,
    double? amount,
    String? categorySlug,
    String? frequency,
    double? categoryConfidence,
    List<String>? categorySuggestions,
    String? memoryKey,
  }) {
    return QuickAddResultModel(
      type: type ?? this.type,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categorySlug: categorySlug ?? this.categorySlug,
      frequency: frequency ?? this.frequency,
      categoryConfidence: categoryConfidence ?? this.categoryConfidence,
      categorySuggestions: categorySuggestions ?? this.categorySuggestions,
      memoryKey: memoryKey ?? this.memoryKey,
    );
  }
}
