import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/exceptions/quick_add_exception.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/local_inference_service.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/quick_add_result_model.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/settings/category_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_add_provider.g.dart';

@riverpod
class QuickAddNotifier extends _$QuickAddNotifier {
  @override
  AsyncValue<QuickAddResultModel?> build() {
    return const AsyncData(null);
  }

  Future<void> parseExpense(String input) async {
    final engine = ref.read(litertEngineProvider).value;
    if (engine == null) {
      state = AsyncError(
        const QuickAddNoModelException(),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();

    try {
      final categories = ref.read(categoryProvider).value ?? [];
      final allExpenses = ref.read(expenseProvider).value ?? [];
      final recurringExpenses = allExpenses
          .where((e) => e.frequency != 'Ponctuel')
          .toList();

      final localService = LocalInferenceService(engine);
      final result = await localService.parseExpense(
        input,
        categories,
        recurringExpenses: recurringExpenses,
      );

      state = AsyncData(result);
    } on QuickAddException catch (e, st) {
      state = AsyncError(e, st);
    } catch (e, st) {
      state = AsyncError(
        QuickAddApiException(message: e.toString()),
        st,
      );
    }
  }

  Future<void> confirmExpense(int accountId) async {
    final result = state.value;
    if (result == null) return;

    try {
      int categoryId;

      if (result.newCategory != null) {
        final icon = CategoryDefaults.icons.containsKey(result.newCategoryIcon)
            ? result.newCategoryIcon!
            : CategoryDefaults.defaultIcon;
        final color = result.newCategoryColor != null
            ? CategoryDefaults.hexToColor(result.newCategoryColor!) ??
                CategoryDefaults.defaultColor
            : CategoryDefaults.defaultColor;

        final newCat = CategoryModel.create(
          name: result.newCategory!,
          icon: icon,
          color: color,
        );
        final repo = ref.read(categoryRepositoryProvider);
        categoryId = repo.add(newCat);
        ref.invalidate(categoryProvider);
      } else {
        categoryId = result.categoryId!;
      }

      final expense = ExpenseModel.create(
        name: result.name,
        amount: result.amount,
        categoryId: categoryId,
        startDate: DateTime.now(),
        frequency: result.frequency,
        accountId: accountId,
      );

      await ref.read(expenseProvider.notifier).addExpense(expense);
      state = const AsyncData(null);
    } catch (e) {
      rethrow;
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}
