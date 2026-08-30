import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';

/// What the app understands from the text currently being typed.
///
/// The fields land progressively : the amount is extracted by regex at every
/// keystroke, the category arrives once the model has run on the pause.
class QuickAddDraft {
  static const double categoryConfidenceThreshold = 0.6;

  /// Where a transaction lands when the model could not name a category.
  /// An unread text is never a reason to refuse an amount the user typed.
  static const String uncategorizedSlug = 'divers.autre';

  final String input;

  /// The text the landed reading actually saw. Everything the model filled in
  /// — name, category, type, recurrence, [memoryKey] — describes this, which
  /// is not always [input] : between a keystroke and the next reading, the
  /// previous one is still on screen.
  final String analyzedInput;

  final double? amount;

  /// The day the transaction lands on. Read from the text, or today when it
  /// names none.
  final DateTime? date;

  /// True once the user picked the day by hand : no later reading of the text
  /// may take it back, an edit a keystroke undoes is not an edit.
  final bool isDatePinned;

  final String? name;
  final String? categorySlug;
  final double categoryConfidence;
  final List<String> categorySuggestions;
  final TransactionType type;
  final Frequency frequency;
  final String? analysisError;

  /// Text a user correction is remembered under, stripped of its amount.
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

  /// True while what is displayed describes an older text than the one being
  /// typed. Nothing read from the model can be trusted, acted on or recorded
  /// until this clears.
  bool get isStale => input != analyzedInput;

  /// A typed amount is all it takes : the category falls back rather than
  /// holding the transaction hostage.
  bool get isSubmittable => (amount ?? 0) > 0;

  /// The category to record, the model's when it named one.
  String get categorySlugOrFallback => categorySlug ?? uncategorizedSlug;

  /// True when the model was not confident enough to stand behind its
  /// category : the chip says so instead of pretending.
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
