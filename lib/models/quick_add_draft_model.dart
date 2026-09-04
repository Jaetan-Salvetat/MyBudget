import 'package:mybudget/core/constants/category_confidence.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';

class QuickAddDraft {
  static const double categoryConfidenceThreshold =
      kCategoryConfidenceThreshold;

  static const String uncategorizedSlug = 'divers.autre';

  final String input;

  final String analyzedInput;

  final double? amount;

  final DateTime? date;

  final bool isDatePinned;

  final String? name;
  final String? categorySlug;
  final double categoryConfidence;
  final List<String> categorySuggestions;
  final TransactionType type;
  final Frequency frequency;
  final String? analysisError;

  final String memoryKey;

  const QuickAddDraft({
    this.input = '',
    this.analyzedInput = '',
    this.amount,
    this.date,
    this.isDatePinned = false,
    this.name,
    this.categorySlug,
    this.categoryConfidence = 0,
    this.categorySuggestions = const [],
    this.type = TransactionType.expense,
    this.frequency = Frequency.oneTime,
    this.analysisError,
    this.memoryKey = '',
  });

  static const QuickAddDraft empty = QuickAddDraft();

  bool get isEmpty => input.trim().isEmpty;

  bool get isStale => input != analyzedInput;

  bool get isSubmittable => (amount ?? 0) > 0;

  String get categorySlugOrFallback => categorySlug ?? uncategorizedSlug;

  bool get isCategoryUncertain =>
      categoryConfidence < categoryConfidenceThreshold;

  QuickAddDraft copyWith({
    String? categorySlug,
    double? categoryConfidence,
    TransactionType? type,
    DateTime? date,
    bool? isDatePinned,
  }) {
    return QuickAddDraft(
      input: input,
      analyzedInput: analyzedInput,
      amount: amount,
      date: date ?? this.date,
      isDatePinned: isDatePinned ?? this.isDatePinned,
      name: name,
      categorySlug: categorySlug ?? this.categorySlug,
      categoryConfidence: categoryConfidence ?? this.categoryConfidence,
      categorySuggestions: categorySuggestions,
      type: type ?? this.type,
      frequency: frequency,
      analysisError: analysisError,
      memoryKey: memoryKey,
    );
  }
}
