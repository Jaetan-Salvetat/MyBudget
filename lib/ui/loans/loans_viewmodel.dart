import 'package:flutter/foundation.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/models/loan_model.dart';

class LoanViewModel extends ChangeNotifier {
  final LoanRepository _loanRepository;

  List<LoanModel> _loans = [];
  bool _isLoading = false;
  String _error = '';

  List<LoanModel> get loans => _loans;
  bool get isLoading => _isLoading;
  String get error => _error;

  LoanViewModel(this._loanRepository) {
    loadLoans();
  }

  Future<void> loadLoans() async {
    try {
      _isLoading = true;
      notifyListeners();

      _loans = _loanRepository.getAll();

      _loans.sort((a, b) {
        if (a.isCompleted() && !b.isCompleted()) return 1;
        if (!a.isCompleted() && b.isCompleted()) return -1;
        return b.startDate.compareTo(a.startDate);
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addLoan(LoanModel loan) async {
    try {
      _isLoading = true;
      notifyListeners();

      _loanRepository.add(loan);
      await loadLoans();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateLoan(LoanModel loan) async {
    try {
      _isLoading = true;
      notifyListeners();

      _loanRepository.update(loan);
      await loadLoans();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteLoan(int id) async {
    try {
      _isLoading = true;
      notifyListeners();

      _loanRepository.delete(id);
      await loadLoans();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  List<LoanModel> getActiveLoans() {
    return _loans.where((loan) => !loan.isCompleted()).toList();
  }

  List<LoanModel> getActiveLoansForAccount(int accountId) {
    return _loans
        .where((loan) => loan.accountId == accountId && !loan.isCompleted())
        .toList();
  }

  List<LoanModel> getCompletedLoans() {
    return _loans.where((loan) => loan.isCompleted()).toList();
  }

  double getTotalRemainingAmount() {
    return getActiveLoans().fold(
      0.0,
      (sum, loan) => sum + loan.getRemainingAmount(),
    );
  }

  double getTotalMonthlyPayments() {
    return getActiveLoans().fold(0.0, (sum, loan) => sum + loan.monthlyPayment);
  }

  double getTotalMonthlyPaymentsForAccount(int accountId) {
    return getActiveLoansForAccount(
      accountId,
    ).fold(0.0, (sum, loan) => sum + loan.monthlyPayment);
  }

  double getTotalActiveInitialAmount() {
    final activeLoans = getActiveLoans();
    return activeLoans.fold(0.0, (sum, loan) => sum + loan.amount);
  }

  double getTotalRemainingCost() {
    return getActiveLoans().fold(0.0, (sum, loan) {
      final totalFuturePayments = loan.remainingMonths * loan.monthlyPayment;
      final remainingPrincipal = loan.remainingCapital;
      final cost = totalFuturePayments - remainingPrincipal;
      return sum + (cost > 0 ? cost : 0);
    });
  }
}
