import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/data/datasources/expense_datasource.dart';
import 'package:mybudget/data/datasources/local/expense_local_datasource.dart';
import 'package:mybudget/data/models/expense_model.dart';
import 'package:mybudget/domain/entities/expense.dart';
import 'package:mybudget/domain/repositories/expense_repository.dart';
import 'package:uuid/uuid.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final cloudDataSource = ref.watch(expenseDataSourceProvider);
  final localDataSource = ref.watch(expenseLocalDataSourceProvider);
  return ExpenseRepositoryImpl(cloudDataSource, localDataSource);
});

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseDataSource _cloudDataSource;
  final ExpenseLocalDataSource _localDataSource;
  final Uuid _uuid = const Uuid();
  bool _isOnlineMode = false;

  ExpenseRepositoryImpl(this._cloudDataSource, this._localDataSource);

  void setOnlineMode(bool isOnline) {
    _isOnlineMode = isOnline;
  }

  Future<Expense> createExpense(
    String name,
    double amount,
    String category,
    DateTime date,
    String frequency,
    String accountId,
  ) async {
    final id = _uuid.v4();
    
    if (_isOnlineMode) {
      return ExpenseModel(
        id: id,
        name: name,
        amount: amount,
        category: category,
        date: date,
        frequency: frequency,
        accountId: accountId,
      );
    } else {
      return await _localDataSource.createExpense(
        id, name, amount, category, date, frequency, accountId);
    }
  }

  @override
  Future<List<Expense>> getExpenses() async {
    if (_isOnlineMode) {
      return [];
    } else {
      return await _localDataSource.getExpenses();
    }
  }

  Future<List<Expense>> getExpensesByAccount(String accountId) async {
    if (_isOnlineMode) {
      return [];
    } else {
      return await _localDataSource.getExpensesByAccount(accountId);
    }
  }

  Future<Expense?> getExpense(String id) async {
    if (_isOnlineMode) {
      return null;
    } else {
      return await _localDataSource.getExpense(id);
    }
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final expenseModel = ExpenseModel(
      id: expense.id,
      name: expense.name,
      amount: expense.amount,
      category: expense.category,
      date: expense.date,
      frequency: expense.frequency,
      accountId: expense.accountId,
    );
    
    if (_isOnlineMode) {
      return;
    } else {
      await _localDataSource.updateExpense(expenseModel);
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    if (_isOnlineMode) {
      return;
    } else {
      await _localDataSource.deleteExpense(id);
    }
  }
  
  @override
  Future<void> addExpense(Expense expense) async {
    final expenseModel = ExpenseModel(
      id: expense.id,
      name: expense.name,
      amount: expense.amount,
      category: expense.category,
      date: expense.date,
      frequency: expense.frequency,
      accountId: expense.accountId,
    );
    
    if (_isOnlineMode) {
      return;
    } else {
      await _localDataSource.create(expenseModel, expense.id);
    }
  }
}
