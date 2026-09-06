import 'package:mybudget/core/enums/effective_month.dart';
import 'package:mybudget/core/enums/recurring_deletion.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/data/model/expense_model.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/data/service/recurring_transaction_editor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'expenses_provider.g.dart';

@Riverpod(keepAlive: true)
class ExpenseNotifier extends _$ExpenseNotifier {
  @override
  Future<List<ExpenseModel>> build() async =>
      byDueDate(ref.watch(expenseRepositoryProvider).getActive());

  RecurringTransactionEditor<ExpenseModel> get _editor =>
      RecurringTransactionEditor<ExpenseModel>(
        repository: ref.read(expenseRepositoryProvider),
        events: () => ref.read(transactionEventRepositoryProvider),
        type: TransactionType.expense,
        now: ref.read(clockProvider),
      );

  Future<int> addExpense(ExpenseModel expense) async {
    final id = ref.read(expenseRepositoryProvider).add(expense);
    await _refresh();
    return id;
  }

  Future<void> updateExpense(
    ExpenseModel updated, {
    EffectiveMonth? effectiveMonth,
  }) async {
    _editor.update(updated, effectiveMonth: effectiveMonth);
    await _refresh();
  }

  Future<void> deletePermanently(int id) async {
    _editor.deletePermanently(id);
    await _refresh();
  }

  Future<void> deleteExpense(
    int id, {
    RecurringDeletion scope = RecurringDeletion.afterThisMonth,
  }) async {
    _editor.deleteFrom(id, scope);
    await _refresh();
  }

  List<ExpenseModel> getClosedExpenses() =>
      ref.read(expenseRepositoryProvider).getClosed();

  List<ExpenseModel> getExpensesForAccount(int accountId) =>
      (state.value ?? const <ExpenseModel>[])
          .where((expense) => expense.accountId == accountId)
          .toList();

  Future<void> _refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
