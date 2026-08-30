import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/recurring_deletion.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/models/expense_model.dart';
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
          return e.startDate.year * 10000 +
              e.startDate.month * 100 +
              e.startDate.day;
      }
    }

    expenses.sort((a, b) => sortKey(a).compareTo(sortKey(b)));
    return expenses;
  }

  Future<int> addExpense(ExpenseModel expense) async {
    try {
      final repo = ref.read(expenseRepositoryProvider);
      final id = repo.add(expense);
      ref.invalidateSelf();
      await future;
      return id;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateExpense(ExpenseModel updated) async {
    try {
      final repo = ref.read(expenseRepositoryProvider);
      final old = repo.get(updated.id);
      if (old == null) return;

      final bool changesTerms =
          updated.amount != old.amount ||
          updated.frequency != old.frequency ||
          updated.accountId != old.accountId ||
          updated.name != old.name ||
          updated.beneficiaryId != old.beneficiaryId;

      if (changesTerms) {
        if (old.frequencyEnum != Frequency.oneTime) {
          final now = DateTime.now();
          final newStartDate = computeNewStartDate(now, old.startDate.day);
          if (hasStarted(old.startDate, now)) {
            repo.update(old.copyWith(endDate: dayOnly(now)));
          } else {
            repo.delete(old.id);
          }
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
      }

      _recategorizeChain(repo, old, updated);

      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  void _recategorizeChain(
    ExpenseRepository repo,
    ExpenseModel old,
    ExpenseModel updated,
  ) {
    if (updated.categorySlug == old.categorySlug) return;

    for (final entry in repo.getChain(old.parentId ?? old.id)) {
      repo.update(entry..categorySlug = updated.categorySlug);
    }
  }

  Future<void> deletePermanently(int id) async {
    ref.read(expenseRepositoryProvider).delete(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteExpense(
    int id, {
    RecurringDeletion scope = RecurringDeletion.afterThisMonth,
  }) async {
    try {
      final repo = ref.read(expenseRepositoryProvider);
      final expense = repo.get(id);
      if (expense == null) return;

      final closing = closingDateOf(
        scope,
        expense.startDate,
        expense.frequencyEnum,
        DateTime.now(),
      );

      if (expense.frequencyEnum == Frequency.oneTime ||
          closing.isBefore(dayOnly(expense.startDate))) {
        await deletePermanently(id);
        return;
      }

      repo.update(expense.copyWith(endDate: closing));
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

  List<ExpenseModel> getExpensesForAccount(int accountId) =>
      (state.value ?? const <ExpenseModel>[])
          .where((expense) => expense.accountId == accountId)
          .toList();
}
