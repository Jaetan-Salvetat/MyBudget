import 'dart:async';

import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/exceptions/quick_add_exception.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/quick_add/price_parser_service.dart';
import 'package:mybudget/core/services/quick_add/quick_add_classification.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/quick_add_draft_model.dart';
import 'package:mybudget/models/quick_add_submission_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_engine_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_add_provider.g.dart';

/// Reads the input as it is typed : the amount lands at every keystroke, the
/// model runs on the pause. Submitting creates the transaction straight away,
/// the snackbar owns the way back.
@riverpod
class QuickAddNotifier extends _$QuickAddNotifier {
  /// Long enough for a pause to read as one, short enough to feel live.
  static const Duration analysisDebounce = Duration(milliseconds: 200);

  Timer? _debounce;
  int _analysisSeq = 0;

  @override
  QuickAddDraft build() {
    ref.onDispose(_cancelPendingAnalysis);
    return QuickAddDraft.empty;
  }

  void onInputChanged(String input) {
    _cancelPendingAnalysis();

    if (input.trim().isEmpty) {
      state = QuickAddDraft.empty;
      return;
    }

    state = _instantDraft(input);

    final seq = _analysisSeq;
    _debounce = Timer(analysisDebounce, () => _analyze(input, seq));
  }

  void selectCategory(String slug) {
    if (state.isEmpty) return;

    ref.read(categoryMemoryProvider).remember(state.memoryKey, slug);
    state = state.copyWith(categorySlug: slug, categoryConfidence: 1.0);
  }

  Future<QuickAddSubmission> submit(int accountId) async {
    final draft = state;
    if (draft.amount == null) {
      throw const QuickAddNoAmountException();
    }
    final categorySlug = draft.categorySlug;
    if (categorySlug == null) {
      throw const QuickAddClassificationException(
        message: 'Aucune catégorie reconnue',
      );
    }

    _cancelPendingAnalysis();
    state = QuickAddDraft.empty;

    final name = draft.name ?? draft.input;
    final amount = draft.amount!;
    final int id;

    if (draft.type == TransactionType.income) {
      id = await ref
          .read(revenueProvider.notifier)
          .addRevenue(
            RevenueModel.create(
              name: name,
              amount: amount,
              startDate: DateTime.now(),
              frequency: draft.frequency.label,
              accountId: accountId,
              categorySlug: categorySlug,
            ),
          );
    } else {
      id = await ref
          .read(expenseProvider.notifier)
          .addExpense(
            ExpenseModel.create(
              name: name,
              amount: amount,
              categorySlug: categorySlug,
              startDate: DateTime.now(),
              frequency: draft.frequency.label,
              accountId: accountId,
            ),
          );
    }

    return QuickAddSubmission(
      id: id,
      type: draft.type,
      name: name,
      amount: amount,
    );
  }

  Future<void> undo(QuickAddSubmission submission) {
    if (submission.type == TransactionType.income) {
      return ref
          .read(revenueProvider.notifier)
          .deletePermanently(submission.id);
    }
    return ref.read(expenseProvider.notifier).deletePermanently(submission.id);
  }

  void reset() {
    _cancelPendingAnalysis();
    state = QuickAddDraft.empty;
  }

  void _cancelPendingAnalysis() {
    _debounce?.cancel();
    _debounce = null;
    _analysisSeq++;
  }

  /// What regex alone can tell, without waiting for the model. The previously
  /// understood category is carried over so the chips refresh instead of
  /// blinking out at every keystroke.
  QuickAddDraft _instantDraft(String input) {
    final previous = state;
    return QuickAddDraft(
      input: input,
      amount: PriceParserService.parse(input)?.price,
      name: previous.name,
      categorySlug: previous.categorySlug,
      categoryConfidence: previous.categoryConfidence,
      categorySuggestions: previous.categorySuggestions,
      type: previous.type,
      frequency: previous.frequency,
      isAnalyzing: true,
      memoryKey: previous.memoryKey,
    );
  }

  Future<void> _analyze(String input, int seq) async {
    try {
      final engine = await ref.read(quickAddEngineProvider.future);
      final classification = await engine.classify(input);
      if (seq != _analysisSeq) return;
      state = _draftFrom(input, classification);
    } on QuickAddException catch (e) {
      if (seq != _analysisSeq) return;
      state = _failedDraft(input, e.message);
    } catch (e) {
      if (seq != _analysisSeq) return;
      state = _failedDraft(input, 'Analyse impossible : $e');
    }
  }

  QuickAddDraft _draftFrom(
    String input,
    QuickAddClassification classification,
  ) {
    // La memoire s'applique apres le modele : elle ne porte que la categorie,
    // le type et la recurrence restent ceux qui viennent d'etre predits.
    final remembered = ref
        .read(categoryMemoryProvider)
        .recall(classification.cleanedText);

    return QuickAddDraft(
      input: input,
      amount: classification.amount,
      name: classification.name,
      categorySlug: remembered ?? classification.categorySlug,
      categoryConfidence: remembered == null
          ? classification.categoryConfidence
          : 1.0,
      categorySuggestions: classification.categorySuggestions,
      type: classification.type,
      frequency: classification.frequency,
      memoryKey: classification.cleanedText,
    );
  }

  QuickAddDraft _failedDraft(String input, String message) {
    return QuickAddDraft(
      input: input,
      amount: PriceParserService.parse(input)?.price,
      analysisError: message,
    );
  }
}
