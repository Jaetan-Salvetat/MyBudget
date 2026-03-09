import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'expenses_provider.g.dart';

@Riverpod(keepAlive: true)
class ExpenseNotifier extends _$ExpenseNotifier {
  @override
  Future<List<ExpenseModel>> build() async {
    final repo = ref.watch(expenseRepositoryProvider);
    final expenses = repo.getAll();

    int sortKey(ExpenseModel e) {
      if (e.frequencyEnum == Frequency.monthly) {
        return e.date.day;
      } else {
        return e.date.month * 100 + e.date.day;
      }
    }

    expenses.sort((a, b) => sortKey(a).compareTo(sortKey(b)));
    return expenses;
  }

  Future<void> addExpense(ExpenseModel expense) async {
    final repo = ref.read(expenseRepositoryProvider);
    repo.add(expense);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    final repo = ref.read(expenseRepositoryProvider);
    repo.update(expense);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteExpense(int id) async {
    final repo = ref.read(expenseRepositoryProvider);
    repo.delete(id);
    ref.invalidateSelf();
    await future;
  }

  // ============= Calculs et filtres =============

  List<ExpenseModel> _currentExpenses() => state.value ?? [];

  double getMonthlyExpenses() => getTotalExpenses(_currentExpenses());

  List<ExpenseModel> getUpcomingExpenses() {
    final now = DateTime.now();
    final upcoming = _currentExpenses().where((expense) {
      if (expense.frequencyEnum == Frequency.monthly) {
        return expense.date.day >= now.day;
      } else if (expense.frequencyEnum == Frequency.annual) {
        return expense.date.month == now.month && expense.date.day >= now.day;
      }
      return expense.date.year == now.year &&
          expense.date.month == now.month &&
          expense.date.day >= now.day;
    }).toList();

    upcoming.sort((a, b) => a.date.day.compareTo(b.date.day));
    return upcoming;
  }

  List<ExpenseModel> getRecentExpenses(int count) =>
      _currentExpenses().take(count).toList();

  Map<CategoryModel, double> getExpensesByCategory() {
    final categoryRepo = ref.read(categoryRepositoryProvider);
    final Map<int, double> categoryTotals = {};

    for (final expense in _currentExpenses()) {
      categoryTotals.update(
        expense.categoryId,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final Map<CategoryModel, double> result = {};
    for (final entry in categoryTotals.entries) {
      final category = categoryRepo.get(entry.key);
      if (category != null) {
        result[category] = entry.value;
      }
    }
    return result;
  }

  List<ExpenseModel> getExpensesForAccount(int accountId) =>
      _currentExpenses()
          .where((expense) => expense.accountId == accountId)
          .toList();

  List<ExpenseModel> getExpensesForCategory(int categoryId) =>
      _currentExpenses()
          .where((expense) => expense.categoryId == categoryId)
          .toList();

  double getTotalExpensesForAccount(int accountId) =>
      getExpensesForAccount(accountId)
          .fold(0.0, (sum, e) => sum + e.amount);

  double getTotalExpenses([List<ExpenseModel>? expensesList]) {
    double total = 0.0;
    final listToUse = expensesList ?? _currentExpenses();

    for (final expense in listToUse) {
      if (expense.frequencyEnum == Frequency.monthly) {
        total += expense.amount;
      } else if (expense.frequencyEnum == Frequency.annual) {
        total += expense.amount / 12;
      }
    }
    return total;
  }

  double getAnnualExpenses([List<ExpenseModel>? expensesList]) {
    double total = 0.0;
    final listToUse = expensesList ?? _currentExpenses();

    for (final expense in listToUse) {
      if (expense.frequencyEnum == Frequency.monthly) {
        total += expense.amount * 12;
      } else if (expense.frequencyEnum == Frequency.annual) {
        total += expense.amount;
      }
    }
    return total;
  }
}
