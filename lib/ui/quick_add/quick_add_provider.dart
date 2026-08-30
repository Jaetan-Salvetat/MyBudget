import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/exceptions/quick_add_exception.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/quick_add/quick_add_classification.dart';
import 'package:mybudget/core/services/quick_add/quick_add_text_reader.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/quick_add_draft_model.dart';
import 'package:mybudget/models/quick_add_submission_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_engine_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_add_provider.g.dart';

/// Reads the input as it is typed : the amount lands at every keystroke, the
/// model runs on the pause. Submitting creates the transaction straight away,
/// the snackbar owns the way back.
@riverpod
class QuickAddNotifier extends _$QuickAddNotifier {
  /// Long enough for a pause to read as one, short enough to feel live.
  static const Duration analysisDebounce = Duration(milliseconds: 200);

  /// Shown when the model could not read the text. It names what the user has
  /// left to do, not what broke : the cause goes to the logs.
  static const String unreadInputMessage =
      'Catégorie non reconnue, choisis-la.';

  Timer? _debounce;
  int _analysisSeq = 0;

  /// The reading currently running, awaited when the user submits before it
  /// has landed.
  Future<void>? _analysisRun;

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
    _debounce = Timer(analysisDebounce, () {
      _analysisRun = _analyze(input, seq);
    });
  }

  /// Pins the day the user picked : it outlives every later reading, and only
  /// goes away with the draft itself.
  void selectDate(DateTime date) {
    if (state.isEmpty) return;
    state = state.copyWith(date: date, isDatePinned: true);
  }

  /// A picked category also settles the type: an income slug on an expense
  /// draft would otherwise record a revenue as a spending.
  void selectCategory(String slug) {
    if (state.isEmpty || state.isStale) return;

    ref.read(categoryMemoryProvider).remember(state.memoryKey, slug);
    state = state.copyWith(
      categorySlug: slug,
      categoryConfidence: 1.0,
      type: _typeOfCategory(slug),
    );
  }

  TransactionType? _typeOfCategory(String slug) =>
      ref.read(categoryDisplayResolverProvider).value?.resolve(slug)?.type;

  Future<QuickAddSubmission> submit(int accountId) async {
    await _settleAnalysis();

    final draft = state;
    if (!draft.isSubmittable) {
      throw const QuickAddNoAmountException();
    }
    final categorySlug = draft.categorySlugOrFallback;

    _cancelPendingAnalysis();
    state = QuickAddDraft.empty;

    final name = draft.name ?? draft.input;
    final amount = draft.amount!;
    final startDate = _recordedAt(draft.date);
    final int id;

    if (draft.type == TransactionType.income) {
      id = await ref
          .read(revenueProvider.notifier)
          .addRevenue(
            RevenueModel.create(
              name: name,
              amount: amount,
              startDate: startDate,
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
              startDate: startDate,
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

  /// Une transaction dite aujourd'hui garde l'heure où elle l'a été : le
  /// journal la range dans son moment de la journée. Un jour passé n'a pas
  /// d'heure à retenir.
  DateTime _recordedAt(DateTime? date) {
    final now = DateTime.now();
    if (date == null) return now;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return now;
    }

    return date;
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
    _analysisRun = null;
    _analysisSeq++;
  }

  /// Brings the reading up to the text being submitted : the pause is cut
  /// short, and a reading already running is waited on. Submitting must never
  /// record what the model saw one keystroke ago.
  Future<void> _settleAnalysis() async {
    final pending = _debounce;
    if (pending != null && pending.isActive) {
      pending.cancel();
      _debounce = null;
      _analysisRun = _analyze(state.input, _analysisSeq);
    }
    await _analysisRun;
  }

  /// What regex alone can tell, without waiting for the model. The previously
  /// understood category is carried over so the chips refresh instead of
  /// blinking out at every keystroke.
  QuickAddDraft _instantDraft(String input) {
    final previous = state;
    final facts = QuickAddTextReader.read(input);
    return QuickAddDraft(
      input: input,
      analyzedInput: previous.analyzedInput,
      amount: facts.amount,
      date: previous.isDatePinned ? previous.date : facts.date,
      isDatePinned: previous.isDatePinned,
      name: previous.name,
      categorySlug: previous.categorySlug,
      categoryConfidence: previous.categoryConfidence,
      categorySuggestions: previous.categorySuggestions,
      type: previous.type,
      frequency: previous.frequency,
      memoryKey: previous.memoryKey,
    );
  }

  Future<void> _analyze(String input, int seq) async {
    try {
      final engine = await ref.read(quickAddEngineProvider.future);
      final classification = await engine.classify(input);
      if (seq != _analysisSeq) return;
      state = _draftFrom(input, classification);
    } catch (error, stackTrace) {
      debugPrint('Analyse de l\'ajout rapide impossible : $error\n$stackTrace');
      if (seq != _analysisSeq) return;
      state = _failedDraft(input, unreadInputMessage);
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

    final previous = state;
    return QuickAddDraft(
      input: input,
      analyzedInput: input,
      amount: classification.amount,
      date: previous.isDatePinned ? previous.date : classification.date,
      isDatePinned: previous.isDatePinned,
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

  /// A reading that failed is still a reading that landed : the draft stops
  /// waiting and keeps what regex alone could tell.
  QuickAddDraft _failedDraft(String input, String message) {
    final previous = state;
    final facts = QuickAddTextReader.read(input);
    return QuickAddDraft(
      input: input,
      analyzedInput: input,
      amount: facts.amount,
      date: previous.isDatePinned ? previous.date : facts.date,
      isDatePinned: previous.isDatePinned,
      analysisError: message,
    );
  }
}
