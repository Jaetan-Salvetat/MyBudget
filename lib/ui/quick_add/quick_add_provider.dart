import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/exceptions/quick_add_exception.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/quick_add/quick_add_classification.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/quick_add_result_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_add_provider.g.dart';

@riverpod
class QuickAddNotifier extends _$QuickAddNotifier {
  @override
  AsyncValue<QuickAddResultModel?> build() {
    return const AsyncData(null);
  }

  Future<void> parse(String input) async {
    state = const AsyncLoading();

    try {
      final classifier = await ref.read(quickAddClassifierProvider.future);
      state = AsyncData(_toResult(await classifier.classify(input)));
    } on QuickAddException catch (e, st) {
      state = AsyncError(e, st);
    } catch (e, st) {
      state = AsyncError(
        QuickAddClassificationException(message: 'Analyse impossible : $e'),
        st,
      );
    }
  }

  void selectCategory(String slug) {
    final result = state.value;
    if (result == null) return;

    ref.read(categoryMemoryProvider).remember(result.memoryKey, slug);

    state = AsyncData(
      result.copyWith(categorySlug: slug, categoryConfidence: 1.0),
    );
  }

  Future<void> confirm(int accountId) async {
    final result = state.value;
    if (result == null) return;

    if (result.categorySlug == null) {
      throw const QuickAddClassificationException(
        message: 'Résultat sans catégorie',
      );
    }

    if (result.type == TransactionType.income) {
      await ref
          .read(revenueProvider.notifier)
          .addRevenue(
            RevenueModel.create(
              name: result.name,
              amount: result.amount,
              startDate: DateTime.now(),
              frequency: result.frequency,
              accountId: accountId,
              categorySlug: result.categorySlug,
            ),
          );
    } else {
      await ref
          .read(expenseProvider.notifier)
          .addExpense(
            ExpenseModel.create(
              name: result.name,
              amount: result.amount,
              categorySlug: result.categorySlug,
              startDate: DateTime.now(),
              frequency: result.frequency,
              accountId: accountId,
            ),
          );
    }

    state = const AsyncData(null);
  }

  void reset() {
    state = const AsyncData(null);
  }

  QuickAddResultModel _toResult(QuickAddClassification classification) {
    // La memoire s'applique apres le modele : elle ne porte que la categorie,
    // le type et la recurrence restent ceux qui viennent d'etre predits.
    final remembered = ref
        .read(categoryMemoryProvider)
        .recall(classification.cleanedText);

    return QuickAddResultModel(
      type: classification.type,
      name: classification.name,
      amount: classification.amount,
      frequency: classification.frequency.label,
      categorySlug: remembered ?? classification.categorySlug,
      categoryConfidence: remembered == null
          ? classification.categoryConfidence
          : 1.0,
      categorySuggestions: classification.categorySuggestions,
      memoryKey: classification.cleanedText,
    );
  }
}
