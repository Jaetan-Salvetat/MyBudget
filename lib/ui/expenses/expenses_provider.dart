import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/providers/selected_month_provider.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';
import 'package:mybudget/utils/history_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'expenses_provider.g.dart';

@Riverpod(keepAlive: true)
class ExpenseNotifier extends _$ExpenseNotifier {
  @override
  Future<List<ExpenseModel>> build() async {
    final repo = ref.watch(expenseRepositoryProvider);
    final expenses = repo.getActive();

    int sortKey(ExpenseModel e) {
      switch (e.frequencyEnum) {
        case Frequency.monthly:
          return e.startDate.day;
        case Frequency.annual:
          return e.startDate.month * 100 + e.startDate.day;
        case Frequency.oneTime:
          return e.startDate.year * 10000 + e.startDate.month * 100 + e.startDate.day;
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

  Future<void> updateExpense(ExpenseModel updated) async {
    try {
      final repo = ref.read(expenseRepositoryProvider);
      final old = repo.get(updated.id);
      if (old == null) return;

      final bool isNameOnly = updated.amount == old.amount &&
          updated.frequency == old.frequency &&
          updated.categorySlug == old.categorySlug &&
          updated.accountId == old.accountId &&
          updated.beneficiaryId == old.beneficiaryId &&
          updated.name != old.name;

      if (isNameOnly) {
        final int rootId = old.parentId ?? old.id;
        final chain = repo.getChain(rootId);
        for (final entry in chain) {
          repo.update(entry.copyWith(name: updated.name));
        }
        ref.invalidateSelf();
        await future;
        return;
      }

      final bool isStructural = updated.amount != old.amount ||
          updated.frequency != old.frequency ||
          updated.categorySlug != old.categorySlug ||
          updated.accountId != old.accountId ||
          updated.beneficiaryId != old.beneficiaryId;

      if (isStructural && old.frequencyEnum != Frequency.oneTime) {
        final now = DateTime.now();
        final endDate = computeEndDate(now, old.startDate.day);
        final newStartDate = computeNewStartDate(now, old.startDate.day);
        repo.update(old.copyWith(endDate: endDate));
        final newExpense = ExpenseModel.create(
          name: updated.name,
          amount: updated.amount,
          categorySlug: updated.categorySlug,
          startDate: newStartDate,
          frequency: updated.frequency,
          accountId: updated.accountId,
          beneficiaryId: updated.beneficiaryId,
          parentId: old.parentId ?? old.id,
        );
        repo.add(newExpense);
      } else {
        repo.update(updated);
      }
      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      final repo = ref.read(expenseRepositoryProvider);
      final expense = repo.get(id);
      if (expense == null) return;

      if (expense.frequencyEnum == Frequency.oneTime) {
        repo.delete(id);
      } else {
        final now = DateTime.now();
        final endDate = computeEndDate(now, expense.startDate.day);
        repo.update(expense.copyWith(endDate: endDate));
      }
      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  List<ExpenseModel> getClosedExpenses() {
    final repo = ref.read(expenseRepositoryProvider);
    return repo.getClosed();
  }

  List<ExpenseModel> _currentExpenses() => state.value ?? [];

  double getMonthlyExpenses() => getTotalExpenses(_currentExpenses());

  List<ExpenseModel> getUpcomingExpenses() {
    final now = DateTime.now();
    final upcoming = _currentExpenses().where((expense) {
      switch (expense.frequencyEnum) {
        case Frequency.monthly:
          return expense.startDate.day >= now.day;
        case Frequency.annual:
          return expense.startDate.month == now.month && expense.startDate.day >= now.day;
        case Frequency.oneTime:
          return false;
      }
    }).toList();

    upcoming.sort((a, b) => a.startDate.day.compareTo(b.startDate.day));
    return upcoming;
  }

  List<ExpenseModel> getRecentExpenses(int count) =>
      _currentExpenses().take(count).toList();

  List<ExpenseModel> getExpensesForAccount(int accountId) =>
      _currentExpenses()
          .where((expense) => expense.accountId == accountId)
          .toList();

  List<ExpenseModel> getExpensesForGroup(String groupKey) {
    final resolver = ref.read(categoryDisplayResolverProvider).value;
    if (resolver == null) return const [];
    return _currentExpenses().where((expense) {
      final slug = expense.categorySlug;
      return slug != null && resolver.groupKeyOf(slug) == groupKey;
    }).toList();
  }

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
          if (expense.startDate.month == selectedMonth.month) {
            total += expense.amount;
          }
        case Frequency.oneTime:
          if (expense.startDate.year == selectedMonth.year &&
              expense.startDate.month == selectedMonth.month) {
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
          if (expense.startDate.year == selectedMonth.year) {
            total += expense.amount;
          }
      }
    }
    return total;
  }
}
