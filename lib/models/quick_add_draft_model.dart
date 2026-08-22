import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';

/// What the app understands from the text currently being typed.
///
/// The fields land progressively : the amount is extracted by regex at every
/// keystroke, the category arrives once the model has run on the pause.
class QuickAddDraft {
  static const double categoryConfidenceThreshold = 0.6;

  final String input;
  final double? amount;
  final String? name;
  final String? categorySlug;
  final double categoryConfidence;
  final List<String> categorySuggestions;
  final TransactionType type;
  final Frequency frequency;
  final bool isAnalyzing;
  final String? analysisError;

  /// Text a user correction is remembered under, stripped of its amount.
  final String memoryKey;

  const QuickAddDraft({
    this.input = '',
    this.amount,
    this.name,
    this.categorySlug,
    this.categoryConfidence = 0,
    this.categorySuggestions = const [],
    this.type = TransactionType.expense,
    this.frequency = Frequency.oneTime,
    this.isAnalyzing = false,
    this.analysisError,
    this.memoryKey = '',
  });

  static const QuickAddDraft empty = QuickAddDraft();

  bool get isEmpty => input.trim().isEmpty;

  /// A transaction needs a positive amount and a category to exist.
  bool get isSubmittable => (amount ?? 0) > 0 && categorySlug != null;

  /// True when the model was not confident enough to stand behind its
  /// category : the chip says so instead of pretending.
  bool get isCategoryUncertain =>
      categoryConfidence < categoryConfidenceThreshold;

  QuickAddDraft copyWith({
    String? categorySlug,
    double? categoryConfidence,
    bool? isAnalyzing,
  }) {
    return QuickAddDraft(
      input: input,
      amount: amount,
      name: name,
      categorySlug: categorySlug ?? this.categorySlug,
      categoryConfidence: categoryConfidence ?? this.categoryConfidence,
      categorySuggestions: categorySuggestions,
      type: type,
      frequency: frequency,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      analysisError: analysisError,
      memoryKey: memoryKey,
    );
  }
}
