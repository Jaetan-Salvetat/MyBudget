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

      // What the rule is, costs, how often, and which account it leaves :
      // change any of that and it is another agreement, so the months already
      // paid keep the one they were paid under. Only the category escapes
      // that rule — see _recategorizeChain.
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

  /// Filing a rule under another category is a correction, never a new
  /// agreement : it says what the rule always was, so it reaches every month
  /// it ever ran and splits nothing on its own.
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

  /// Hard delete, whatever the recurrence : closing a row makes no sense when
  /// it was created seconds ago.
  Future<void> deletePermanently(int id) async {
    ref.read(expenseRepositoryProvider).delete(id);
    ref.invalidateSelf();
    await future;
  }

  /// A recurring rule is closed rather than erased : the months it was
  /// actually paid in are history, and history is what this app keeps. What
  /// [scope] settles is whether the month in progress is one of them.
  ///
  /// A rule left with nothing to defend — a one-off, or one closing before it
  /// ever came round — is erased instead.
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
