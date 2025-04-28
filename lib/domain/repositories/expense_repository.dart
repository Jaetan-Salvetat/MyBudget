import 'package:mybudget/domain/entities/expense.dart';

abstract class ExpenseRepository {
  Future<void> addExpense(Expense expense);
  Future<List<Expense>> getExpenses();
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense(String id);
}