import 'package:flutter/foundation.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/transfer_repository.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/core/enums/annual_expense_calculation_mode.dart';
import 'package:mybudget/models/transaction_item.dart';
import 'package:mybudget/models/transfer_model.dart';
import 'package:mybudget/ui/expenses/expenses_viewmodel.dart';
import 'package:mybudget/ui/revenues/revenues_viewmodel.dart';
import 'package:mybudget/ui/loans/loans_viewmodel.dart';

class AccountViewModel extends ChangeNotifier {
  final AccountRepository _accountRepository;
  final TransferRepository _transferRepository;
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
    this._transferRepository,
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

    final accountTransfers = _transferRepository.getByAccount(accountId);

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

    final transfersBalance = accountTransfers.fold<double>(0.0, (
      sum,
      transfer,
    ) {
      if (transfer.sourceAccountId == accountId) {
        return sum - transfer.amount; // Money going out
      } else if (transfer.destinationAccountId == accountId) {
        return sum + transfer.amount; // Money coming in
      }
      return sum;
    });

    return totalRevenues - totalExpenses - totalLoanPayments + transfersBalance;
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

  void createTransfer(TransferModel transfer) {
    _transferRepository.create(transfer);
    notifyListeners();
  }

  Future<void> deleteTransaction(TransactionItem item) async {
    try {
      _isLoading = true;
      notifyListeners();

      switch (item.type) {
        case TransactionType.expense:
          await _expenseViewModel.deleteExpense(item.id);
          break;
        case TransactionType.income:
          await _revenueViewModel.deleteRevenue(item.id);
          break;
        case TransactionType.loan:
          await _loanViewModel.deleteLoan(item.id);
          break;
        case TransactionType.transfer:
          _transferRepository.delete(item.id);
          break;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<TransactionItem> getTransactionsForAccount(int accountId) {
    final transactions = <TransactionItem>[];

    transactions.addAll(
      _expenseViewModel
          .getExpensesForAccount(accountId)
          .map(
            (expense) => TransactionItem(
              id: expense.id,
              label: expense.name,
              type: TransactionType.expense,
              amount: -expense.amount,
              date: expense.date,
            ),
          ),
    );
    transactions.addAll(
      _revenueViewModel
          .getRevenuesForAccount(accountId)
          .map(
            (revenue) => TransactionItem(
              id: revenue.id,
              label: revenue.name,
              type: TransactionType.income,
              amount: revenue.amount,
              date: revenue.date,
            ),
          ),
    );
    transactions.addAll(
      _loanViewModel
          .getActiveLoansForAccount(accountId)
          .map(
            (loan) => TransactionItem(
              id: loan.id,
              label: loan.name,
              type: TransactionType.loan,
              amount: loan.monthlyPayment,
              date: DateTime.now().subtract(Duration(days: loan.dayOfMonth)),
            ),
          ),
    );
    transactions.addAll(
      _transferRepository
          .getByAccount(accountId)
          .map(
            (transfer) => TransactionItem(
              id: transfer.id,
              label: transfer.name,
              type: TransactionType.transfer,
              amount:
                  transfer.sourceAccountId == accountId
                      ? -transfer.amount
                      : transfer.amount,
              date: transfer.date,
            ),
          ),
    );

    transactions.sort((a, b) => b.date.day.compareTo(a.date.day));
    return transactions;
  }
}
