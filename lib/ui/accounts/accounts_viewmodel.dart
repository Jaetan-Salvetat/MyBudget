import 'package:flutter/foundation.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/core/enums/annual_expense_calculation_mode.dart';
import 'package:mybudget/ui/expenses/expenses_viewmodel.dart';
import 'package:mybudget/ui/revenues/revenues_viewmodel.dart';
import 'package:mybudget/ui/loans/loans_viewmodel.dart';

class AccountViewModel extends ChangeNotifier {
  final AccountRepository _accountRepository;
  final ExpenseViewModel _expenseViewModel;
  final RevenueViewModel _revenueViewModel;
  final LoanViewModel _loanViewModel;

  List<AccountModel> _accounts = [];
  bool _isLoading = false;
  String _error = '';

  List<AccountModel> get accounts => _accounts;
  bool get isLoading => _isLoading;
  String get error => _error;

  AccountViewModel(
    this._accountRepository,
    this._expenseViewModel,
    this._revenueViewModel,
    this._loanViewModel,
  ) {
    _loadAccounts();

    _expenseViewModel.addListener(_notifyListeners);
    _revenueViewModel.addListener(_notifyListeners);
    _loanViewModel.addListener(_notifyListeners);
  }

  void _notifyListeners() {
    notifyListeners();
  }

  @override
  void dispose() {
    _expenseViewModel.removeListener(_notifyListeners);
    _revenueViewModel.removeListener(_notifyListeners);
    _loanViewModel.removeListener(_notifyListeners);
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    try {
      _isLoading = true;
      notifyListeners();

      _accounts = _accountRepository.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getAccounts() async {
    await _loadAccounts();
  }

  Future<void> addAccount(AccountModel account) async {
    try {
      _isLoading = true;
      notifyListeners();

      _accountRepository.add(account);
      await _loadAccounts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateAccount(AccountModel account) async {
    try {
      _isLoading = true;
      notifyListeners();

      _accountRepository.update(account);
      await _loadAccounts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteAccount(int id) async {
    try {
      _isLoading = true;
      notifyListeners();

      _accountRepository.delete(id);
      await _loadAccounts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  double getAccountBalance(int accountId) {
    final accountRevenues =
        _revenueViewModel.revenues
            .where((revenue) => revenue.accountId == accountId)
            .toList();

    final accountExpenses =
        _expenseViewModel.expenses
            .where((expense) => expense.accountId == accountId)
            .toList();

    final activeLoans =
        _loanViewModel.loans
            .where((loan) => loan.accountId == accountId && !loan.isCompleted())
            .toList();

    final totalRevenues = accountRevenues.fold<double>(
      0.0,
      (sum, revenue) => sum + revenue.amount,
    );

    final totalExpenses = accountExpenses.fold<double>(
      0.0,
      (sum, expense) => sum + expense.amount,
    );

    final totalLoanPayments = activeLoans.fold<double>(
      0.0,
      (sum, loan) => sum + loan.monthlyPayment,
    );

    return totalRevenues - totalExpenses - totalLoanPayments;
  }

  double getTotalBalance() {
    double total = 0.0;

    for (final account in _accounts) {
      total += getAccountBalance(account.id);
    }

    return total;
  }

  double getNetCashFlow([AnnualExpenseCalculationMode? calculationMode]) {
    final monthlyRevenues = _revenueViewModel.getMonthlyRevenues();

    final monthlyExpenses = _expenseViewModel.getMonthlyExpenses(
      calculationMode ?? AnnualExpenseCalculationMode.monthlyAmortized,
    );
    final monthlyLoanPayments = _loanViewModel.getTotalMonthlyPayments();

    return monthlyRevenues - (monthlyExpenses + monthlyLoanPayments);
  }

  double getSavingsRate([AnnualExpenseCalculationMode? calculationMode]) {
    final monthlyRevenues = _revenueViewModel.getMonthlyRevenues();

    if (monthlyRevenues <= 0) return 0.0;

    final netCashFlow = getNetCashFlow(calculationMode);
    return (netCashFlow / monthlyRevenues) * 100;
  }

  int getTotalTransactionsCount() {
    return _expenseViewModel.expenses.length +
        _revenueViewModel.revenues.length +
        _loanViewModel.getActiveLoans().length;
  }
}
