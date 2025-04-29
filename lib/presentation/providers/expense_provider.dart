import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/domain/entities/expense.dart';
import 'package:mybudget/domain/repositories/expense_repository.dart';
import 'package:mybudget/data/repositories/expense_repository_impl.dart';



final expenseNotifierProvider = StateNotifierProvider<ExpenseNotifier, List<Expense>>(
  (ref) {
    final repository = ref.watch(expenseRepositoryProvider);
    return ExpenseNotifier(repository);
  },
);

class ExpenseNotifier extends StateNotifier<List<Expense>> {
  final ExpenseRepository _repository;

  ExpenseNotifier(this._repository) : super([]) {
    getExpenses();
  }

  Future<void> getExpenses() async {
    final expenses = await _repository.getExpenses();
    state = expenses;
  }

  Future<void> addExpense(Expense expense) async {
    await _repository.addExpense(expense);
    await getExpenses();
  }
  
  Future<void> updateExpense(Expense expense) async {
    await _repository.updateExpense(expense);
    await getExpenses();
  }
  
  Future<void> deleteExpense(String id) async {
    await _repository.deleteExpense(id);
    await getExpenses();
  }
}
