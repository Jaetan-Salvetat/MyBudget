import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/providers/selected_month_provider.dart';
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
      switch (e.frequencyEnum) {
        case Frequency.monthly:
          return e.date.day;
        case Frequency.annual:
          return e.date.month * 100 + e.date.day;
        case Frequency.oneTime:
          return e.date.year * 10000 + e.date.month * 100 + e.date.day;
      }
    }

    expenses.sort((a, b) => sortKey(a).compareTo(sortKey(b)));
    return expenses;
  }

  Future<void> addExpense(ExpenseModel expense) async {
    try {
      final repo = ref.read(expenseRepositoryProvider);
      repo.add(expense);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      final repo = ref.read(expenseRepositoryProvider);
      repo.update(expense);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      final repo = ref.read(expenseRepositoryProvider);
      repo.delete(id);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  List<ExpenseModel> _currentExpenses() => state.value ?? [];

  double getMonthlyExpenses() => getTotalExpenses(_currentExpenses());

  List<ExpenseModel> getUpcomingExpenses() {
    final now = DateTime.now();
    final upcoming = _currentExpenses().where((expense) {
      switch (expense.frequencyEnum) {
        case Frequency.monthly:
          return expense.date.day >= now.day;
        case Frequency.annual:
          return expense.date.month == now.month && expense.date.day >= now.day;
        case Frequency.oneTime:
          final expenseDate = DateTime(
            expense.date.year,
            expense.date.month,
            expense.date.day,
          );
          final today = DateTime(now.year, now.month, now.day);
          return !expenseDate.isBefore(today);
      }
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
    final selectedMonth = ref.read(selectedMonthProvider);
    double total = 0.0;
    final listToUse = expensesList ?? _currentExpenses();

    for (final expense in listToUse) {
      switch (expense.frequencyEnum) {
        case Frequency.monthly:
          total += expense.amount;
        case Frequency.annual:
          if (expense.date.month == selectedMonth.month) {
            total += expense.amount;
          }
        case Frequency.oneTime:
          if (expense.date.year == selectedMonth.year &&
              expense.date.month == selectedMonth.month) {
            total += expense.amount;
          }
      }
    }
    return total;
  }

  double getAnnualExpenses([List<ExpenseModel>? expensesList]) {
    final selectedMonth = ref.read(selectedMonthProvider);
    double total = 0.0;
    final listToUse = expensesList ?? _currentExpenses();

    for (final expense in listToUse) {
      switch (expense.frequencyEnum) {
        case Frequency.monthly:
          total += expense.amount * 12;
        case Frequency.annual:
          total += expense.amount;
        case Frequency.oneTime:
          if (expense.date.year == selectedMonth.year) {
            total += expense.amount;
          }
      }
    }
    return total;
  }
}
