import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/services/hive_service.dart';
import 'package:mybudget/data/datasources/local/base_local_datasource.dart';
import 'package:mybudget/data/models/expense_model.dart';

final expenseLocalDataSourceProvider = Provider<ExpenseLocalDataSource>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return ExpenseLocalDataSource(hiveService);
});

class ExpenseLocalDataSource extends BaseLocalDataSource<ExpenseModel> {
  final HiveService _hiveService;
  
  ExpenseLocalDataSource(this._hiveService) : super('expenses');
  
  Future<void> initialize() async {
    await _hiveService.init();
  }
  
  Future<ExpenseModel> createExpense(
    String id,
    String name,
    double amount,
    String category,
    DateTime date,
    String frequency,
    String accountId,
  ) async {
    final expense = ExpenseModel(
      id: id,
      name: name,
      amount: amount,
      category: category,
      date: date,
      frequency: frequency,
      accountId: accountId,
    );
    await create(expense, id);
    return expense;
  }
  
  Future<List<ExpenseModel>> getExpenses() async {
    return await getAll();
  }
  
  Future<List<ExpenseModel>> getExpensesByAccount(String accountId) async {
    final expenses = await getAll();
    return expenses.where((expense) => expense.accountId == accountId).toList();
  }
  
  Future<ExpenseModel?> getExpense(String id) async {
    return await get(id);
  }
  
  Future<void> updateExpense(ExpenseModel expense) async {
    await update(expense.id, expense);
  }
  
  Future<void> deleteExpense(String id) async {
    await delete(id);
  }
}
