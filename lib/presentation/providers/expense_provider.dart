import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/usecases/usecase.dart';
import 'package:mybudget/domain/entities/expense.dart';
import 'package:mybudget/domain/usecases/add_expense_usecase.dart';
import 'package:mybudget/domain/usecases/get_expenses_usecase.dart';

class ExpenseNotifier extends StateNotifier<List<Expense>> {
  final GetExpensesUseCase getExpensesUseCase;
  final AddExpenseUseCase addExpenseUseCase;
  
  ExpenseNotifier({required this.getExpensesUseCase, required this.addExpenseUseCase}) : super([]);

  Future<void> getExpenses() async {
    final expenses = await getExpensesUseCase(NoParams());
    state = expenses;
  }

  Future<void> addExpense(Expense expense) async {
    await addExpenseUseCase(AddExpenseParams(expense: expense));
    getExpenses();
  }
}