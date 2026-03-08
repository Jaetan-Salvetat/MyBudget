import 'package:flutter/foundation.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/category_repository.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/core/enums/frequency.dart';

class ExpenseViewModel extends ChangeNotifier {
  final ExpenseRepository _expenseRepository;
  final CategoryRepository _categoryRepository;

  List<ExpenseModel> _expenses = [];
  bool _isLoading = false;
  String _error = '';

  List<ExpenseModel> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String get error => _error;

  ExpenseViewModel(this._expenseRepository, this._categoryRepository) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    try {
      _isLoading = true;
      notifyListeners();

      _expenses = _expenseRepository.getAll();

      int sortKey(ExpenseModel e) {
        if (e.frequencyEnum == Frequency.monthly) {
          return e.date.day;
        } else {
          return e.date.month * 100 + e.date.day;
        }
      }

      _expenses.sort((a, b) => sortKey(a).compareTo(sortKey(b)));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense(ExpenseModel expense) async {
    try {
      _isLoading = true;
      notifyListeners();

      _expenseRepository.add(expense);
      await loadExpenses();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      _isLoading = true;
      notifyListeners();

      _expenseRepository.update(expense);
      await loadExpenses();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      _isLoading = true;
      notifyListeners();

      _expenseRepository.delete(id);
      await loadExpenses();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  double getMonthlyExpenses() {
    return getTotalExpenses(_expenses);
  }

  List<ExpenseModel> getUpcomingExpenses() {
    final now = DateTime.now();
    final upcoming =
        _expenses.where((expense) {
          if (expense.frequencyEnum == Frequency.monthly) {
            return expense.date.day >= now.day;
          } else if (expense.frequencyEnum == Frequency.annual) {
            return expense.date.month == now.month &&
                expense.date.day >= now.day;
          }

          return expense.date.year == now.year &&
              expense.date.month == now.month &&
              expense.date.day >= now.day;
        }).toList();

    upcoming.sort((a, b) => a.date.day.compareTo(b.date.day));
    return upcoming;
  }

  List<ExpenseModel> getRecentExpenses(int count) {
    return _expenses.take(count).toList();
  }

  Map<CategoryModel, double> getExpensesByCategory() {
    final Map<int, double> categoryTotals = {};

    for (var expense in _expenses) {
      categoryTotals.update(
        expense.categoryId,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final Map<CategoryModel, double> result = {};
    for (var entry in categoryTotals.entries) {
      final category = _categoryRepository.get(entry.key);
      if (category != null) {
        result[category] = entry.value;
      }
    }

    return result;
  }

  List<ExpenseModel> getExpensesForAccount(int accountId) {
    return _expenses
        .where((expense) => expense.accountId == accountId)
        .toList();
  }

  double getTotalExpensesForAccount(int accountId) {
    return getExpensesForAccount(
      accountId,
    ).fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double getTotalExpenses([List<ExpenseModel>? expensesList]) {
    double total = 0.0;
    final listToUse = expensesList ?? _expenses;

    for (var expense in listToUse) {
      if (expense.frequencyEnum == Frequency.monthly) {
        total += expense.amount;
      } else if (expense.frequencyEnum == Frequency.annual) {
        // Les dépenses annuelles sont amorties sur 12 mois
        total += expense.amount / 12;
      }
    }

    return total;
  }

  double getAnnualExpenses([List<ExpenseModel>? expensesList]) {
    double total = 0.0;
    final listToUse = expensesList ?? _expenses;

    for (var expense in listToUse) {
      if (expense.frequencyEnum == Frequency.monthly) {
        total += expense.amount * 12;
      } else if (expense.frequencyEnum == Frequency.annual) {
        total += expense.amount;
      }
    }

    return total;
  }
}
