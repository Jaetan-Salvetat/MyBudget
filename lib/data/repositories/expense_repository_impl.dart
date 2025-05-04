import 'package:mybudget/data/datasources/expense_datasource.dart';
import 'package:mybudget/data/models/expense_model.dart';
import 'package:mybudget/domain/entities/expense.dart';
import 'package:mybudget/domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseDatasource _expenseDatasource;

  ExpenseRepositoryImpl() : _expenseDatasource = ExpenseDatasource();

  @override
  Future<List<Expense>> getExpenses() async {
    return await _expenseDatasource.getExpenses();
  }
  
  @override
  Future<void> addExpense(Expense expense) async {
    if (expense is ExpenseModel) {
      await _expenseDatasource.createExpense(expense);
    } else {
      final expenseModel = ExpenseModel(
        id: expense.id,
        name: expense.name,
        amount: expense.amount,
        category: expense.category,
        date: expense.date,
        frequency: expense.frequency,
        accountId: expense.accountId
      );
      await _expenseDatasource.createExpense(expenseModel);
    }
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    if (expense is ExpenseModel) {
      await _expenseDatasource.updateExpense(expense);
    } else {
      final expenseModel = ExpenseModel(
        id: expense.id,
        name: expense.name,
        amount: expense.amount,
        category: expense.category,
        date: expense.date,
        frequency: expense.frequency,
        accountId: expense.accountId
      );
      await _expenseDatasource.updateExpense(expenseModel);
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _expenseDatasource.deleteExpense(id);
  }
}
