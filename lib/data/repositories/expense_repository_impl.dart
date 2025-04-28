import 'package:mybudget/data/datasources/local_data_source.dart';
import 'package:mybudget/data/models/expense_model.dart';
import 'package:mybudget/domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final LocalDataSource localDataSource;

  final String _key = "expenses";

  ExpenseRepositoryImpl(this.localDataSource);

  @override
  Future<List<Expense>> getExpenses() async {
    final List<dynamic> expenseMap = await localDataSource.getData(key: _key) ?? [];
    return expenseMap.map((model) => ExpenseModel.fromJson(model)).toList();
  }

  @override
  Future<void> addExpense(Expense expense) async {
    final List<Expense> expenses = await getExpenses();
    expenses.add(expense);
    await localDataSource.saveData(key: _key, value: expenses.map((e) => e.toJson()).toList());
  }

  @override
  Future<void> deleteExpense(String id) async {
    final List<Expense> expenses = await getExpenses();
    expenses.removeWhere((expense) => expense.id == id);
    await localDataSource.saveData(key: _key, value: expenses.map((e) => e.toJson()).toList());
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final List<Expense> expenses = await getExpenses();
    expenses[expenses.indexWhere((e) => e.id == expense.id)] = expense;
    await localDataSource.saveData(key: _key, value: expenses.map((e) => e.toJson()).toList());
  }
}