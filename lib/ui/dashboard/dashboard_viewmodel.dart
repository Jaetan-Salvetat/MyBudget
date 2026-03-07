import 'package:flutter/material.dart';
import 'package:mybudget/ui/accounts/accounts_viewmodel.dart';
import 'package:mybudget/ui/expenses/expenses_viewmodel.dart';
import 'package:mybudget/ui/revenues/revenues_viewmodel.dart';
import 'package:mybudget/ui/loans/loans_viewmodel.dart';
import 'package:mybudget/ui/settings/settings_viewmodel.dart';
import 'package:mybudget/ui/dashboard/models/category_expense_summary.dart';

class DashboardViewModel extends ChangeNotifier {
  final AccountViewModel _accountViewModel;
  final ExpenseViewModel _expenseViewModel;
  final RevenueViewModel _revenueViewModel;
  final LoanViewModel _loanViewModel;
  final SettingsViewModel _settingsViewModel;

  DashboardViewModel(
    this._accountViewModel,
    this._expenseViewModel,
    this._revenueViewModel,
    this._loanViewModel,
    this._settingsViewModel,
  ) {
    _accountViewModel.addListener(notifyListeners);
    _expenseViewModel.addListener(notifyListeners);
    _revenueViewModel.addListener(notifyListeners);
    _loanViewModel.addListener(notifyListeners);
    _settingsViewModel.addListener(notifyListeners);
  }

  @override
  void dispose() {
    _accountViewModel.removeListener(notifyListeners);
    _expenseViewModel.removeListener(notifyListeners);
    _revenueViewModel.removeListener(notifyListeners);
    _loanViewModel.removeListener(notifyListeners);
    _settingsViewModel.removeListener(notifyListeners);
    super.dispose();
  }

  double get netCashFlow => _accountViewModel.getNetCashFlow();

  double get savingsRate => _accountViewModel.getSavingsRate();

  double get totalLoanAmount => _loanViewModel.getTotalRemainingAmount();

  double get monthlyExpenses => _expenseViewModel.getMonthlyExpenses();

  double get monthlyRevenues => _revenueViewModel.getMonthlyRevenues();

  double get totalMonthlyLoanPayments =>
      _loanViewModel.getTotalMonthlyPayments();

  double get totalExpenses => monthlyExpenses + totalMonthlyLoanPayments;

  List<CategoryExpenseSummary> get categorySummaries {
    final categoryExpensesMap = _expenseViewModel.getExpensesByCategory();
    final List<CategoryExpenseSummary> summaries = [];
    final total = totalExpenses;

    if (total > 0) {
      categoryExpensesMap.forEach((category, amount) {
        summaries.add(
          CategoryExpenseSummary(
            categoryName: category.name,
            amount: amount,
            percentage: amount / total,
            color: Color(category.color),
            icon: category.getIconData(),
            categoryId: category.id,
          ),
        );
      });

      summaries.sort((a, b) => b.amount.compareTo(a.amount));
    }
    return summaries;
  }
}
