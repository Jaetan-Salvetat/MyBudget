import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/providers.dart';
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

  /// Returns the id of the created row, so a caller can undo its own add.
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

      // What the rule costs, how often, and which account it leaves : change
      // any of that and it is another agreement, so the months already paid
      // keep the one they were paid under.
      final bool changesTerms =
          updated.amount != old.amount ||
          updated.frequency != old.frequency ||
          updated.accountId != old.accountId;

      // Everything else only describes the rule. Filing a subscription under
      // the right category is a correction, and a correction is true of every
      // month it ever ran — so it reaches the whole chain and splits nothing.
      if (!changesTerms) {
        for (final entry in repo.getChain(old.parentId ?? old.id)) {
          repo.update(
            entry
              ..name = updated.name
              ..categorySlug = updated.categorySlug
              ..beneficiaryId = updated.beneficiaryId,
          );
        }
        ref.invalidateSelf();
        await future;
        return;
      }

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
      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  /// Hard delete, whatever the recurrence : closing a row makes no sense when
  /// it was created seconds ago.
  Future<void> deletePermanently(int id) async {
    ref.read(expenseRepositoryProvider).delete(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteExpense(int id) async {
    try {
      final repo = ref.read(expenseRepositoryProvider);
      final expense = repo.get(id);
      if (expense == null) return;

      final now = DateTime.now();
      // A recurring rule is closed rather than erased : the months it was
      // actually paid in are history, and history is what this app keeps.
      // One that never came round has no such months to defend.
      if (expense.frequencyEnum == Frequency.oneTime ||
          !hasStarted(expense.startDate, now)) {
        await deletePermanently(id);
        return;
      }

      repo.update(expense.copyWith(endDate: dayOnly(now)));
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
