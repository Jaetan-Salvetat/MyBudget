import 'package:mybudget/core/enums/effective_month.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/recurring_deletion.dart';
import 'package:mybudget/core/entities/transaction_change_entry.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/transaction_change_service.dart';
import 'package:mybudget/models/transaction_event_model.dart';
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

  Future<void> updateExpense(
    ExpenseModel updated, {
    EffectiveMonth? effectiveMonth,
  }) async {
    try {
      final repo = ref.read(expenseRepositoryProvider);
      final old = repo.get(updated.id);
      if (old == null) return;

      final changesTerms = TransactionChangeService.changesTerms(old, updated);
      final forked = changesTerms && old.frequencyEnum != Frequency.oneTime;

      if (forked) {
        _fork(repo, old, updated, effectiveMonth);
      } else if (changesTerms) {
        repo.update(updated);
      }

      _recordChanges(old, updated, forked: forked);
      _recategorizeChain(repo, old, updated);

      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  void _fork(
    ExpenseRepository repo,
    ExpenseModel old,
    ExpenseModel updated,
    EffectiveMonth? effectiveMonth,
  ) {
    final now = DateTime.now();
    final frequency = updated.frequencyEnum;
    final scope =
        effectiveMonth ??
        defaultEffectiveMonth(
          frequency: frequency,
          anchor: updated.startDate,
          asOf: now,
        );
    final startDate = startDateFor(
      frequency: frequency,
      anchor: updated.startDate,
      asOf: now,
      scope: scope,
    );
    final closing = startDate.subtract(const Duration(days: 1));

    if (hasStarted(old.startDate, closing)) {
      repo.update(old.copyWith(endDate: dayOnly(closing)));
    } else {
      repo.delete(old.id);
    }

    repo.add(
      ExpenseModel.create(
        name: updated.name,
        amount: updated.amount,
        categorySlug: updated.categorySlug,
        startDate: startDate,
        frequency: updated.frequency,
        accountId: updated.accountId,
        beneficiaryId: updated.beneficiaryId,
        parentId: old.parentId ?? old.id,
      ),
    );
  }

  void _recordChanges(
    ExpenseModel old,
    ExpenseModel updated, {
    required bool forked,
  }) {
    final changes = TransactionChangeService.inPlaceChanges(
      old,
      updated,
      at: DateTime.now(),
      forked: forked,
    );
    if (changes.isEmpty) return;

    final events = ref.read(transactionEventRepositoryProvider);
    final rootId = old.parentId ?? old.id;
    for (final TransactionChangeEntry change in changes) {
      events.add(
        TransactionEventModel.create(
          rootId: rootId,
          type: TransactionType.expense,
          entry: change,
        ),
      );
    }
  }

  void _forgetOrphanEvents(ExpenseRepository repo, ExpenseModel deleted) {
    final rootId = deleted.parentId ?? deleted.id;
    if (repo.getChain(rootId).isNotEmpty) return;

    ref
        .read(transactionEventRepositoryProvider)
        .deleteForRoot(rootId, TransactionType.expense);
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
    final repo = ref.read(expenseRepositoryProvider);
    final expense = repo.get(id);
    repo.delete(id);
    if (expense != null) _forgetOrphanEvents(repo, expense);
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
