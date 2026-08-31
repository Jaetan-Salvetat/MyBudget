import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mybudget/core/enums/ai_request_failure.dart';
import 'package:mybudget/core/enums/gemini_nano_failure.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
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
import 'package:mybudget/ui/quick_add/quick_add_alert_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_engine_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_add_provider.g.dart';

@riverpod
class QuickAddNotifier extends _$QuickAddNotifier {
  static const Duration analysisDebounce = Duration(milliseconds: 200);

  static const String unreadInputMessage =
      'Catégorie non reconnue, choisis-la.';

  Timer? _debounce;
  int _analysisSeq = 0;

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

  void selectDate(DateTime date) {
    if (state.isEmpty) return;
    state = state.copyWith(date: date, isDatePinned: true);
  }

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

  Future<void> _settleAnalysis() async {
    final pending = _debounce;
    if (pending != null && pending.isActive) {
      pending.cancel();
      _debounce = null;
      _analysisRun = _analyze(state.input, _analysisSeq);
    }
    await _analysisRun;
  }

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

      final engineFailure = _engineFailureMessage(error);
      if (engineFailure != null) {
        ref.read(quickAddAlertProvider.notifier).report(engineFailure);
        state = _failedDraft(input, null);
        return;
      }
      state = _failedDraft(input, unreadInputMessage);
    }
  }

  String? _engineFailureMessage(Object error) {
    if (error is GeminiNanoException) return error.message;
    if (error is AiRequestException &&
        ref.read(quickAddEngineModeProvider) == QuickAddEngineMode.geminiNano) {
      return GeminiNanoFailure.malformedResponse.message;
    }
    return null;
  }

  QuickAddDraft _draftFrom(
    String input,
    QuickAddClassification classification,
  ) {
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

  QuickAddDraft _failedDraft(String input, String? message) {
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
