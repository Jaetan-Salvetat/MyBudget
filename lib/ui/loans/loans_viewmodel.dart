import 'package:flutter/foundation.dart';
import 'package:mybudget/core/domain/loan.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/services/loan_service.dart';
import 'package:mybudget/models/loan_model.dart';

/// ViewModel pour la gestion des prêts
/// Responsabilité : Gérer l'état de la liste des prêts et les opérations CRUD
/// La logique métier complexe est déléguée aux entités Loan
class LoanViewModel extends ChangeNotifier {
  final LoanRepository _loanRepository;
  final LoanService _loanService = LoanService();

  List<Loan> _loans = [];
  bool _isLoading = false;
  String _error = '';

  List<Loan> get loans => _loans;
  bool get isLoading => _isLoading;
  String get error => _error;

  LoanViewModel(this._loanRepository) {
    loadLoans();
  }

  Future<void> loadLoans() async {
    try {
      _isLoading = true;
      notifyListeners();

      final models = _loanRepository.getAll();
      _loans = _loanService.createLoans(models);

      // Tri : prêts actifs d'abord, puis par date de début
      _loans.sort((a, b) {
        if (a.isCompleted && !b.isCompleted) return 1;
        if (!a.isCompleted && b.isCompleted) return -1;
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

  // ============= Filtres et agrégations =============
  // Pas de logique métier complexe ici, juste des filtres simples

  List<Loan> getActiveLoans() {
    return _loans.where((loan) => !loan.isCompleted).toList();
  }

  List<Loan> getActiveLoansForAccount(int accountId) {
    return _loans
        .where((loan) => loan.accountId == accountId && !loan.isCompleted)
        .toList();
  }

  List<Loan> getCompletedLoans() {
    return _loans.where((loan) => loan.isCompleted).toList();
  }

  // ============= Totaux et statistiques =============

  double getTotalRemainingAmount() {
    return getActiveLoans().fold(
      0.0,
      (sum, loan) => sum + loan.remainingCapital,
    );
  }

  double getTotalMonthlyPayments() {
    return getActiveLoans().fold(
      0.0,
      (sum, loan) => sum + loan.currentMonthlyPayment,
    );
  }

  double getTotalMonthlyPaymentsForAccount(int accountId) {
    return getActiveLoansForAccount(accountId).fold(
      0.0,
      (sum, loan) => sum + loan.currentMonthlyPayment,
    );
  }

  double getTotalActiveInitialAmount() {
    final activeLoans = getActiveLoans();
    return activeLoans.fold(0.0, (sum, loan) => sum + loan.amount);
  }

  double getTotalRemainingCost() {
    return getActiveLoans().fold(
      0.0,
      (sum, loan) => sum + loan.remainingCost,
    );
  }

  /// Pourcentage de progression global (moyenne pondérée)
  double getOverallProgressPercentage() {
    final activeLoans = getActiveLoans();
    if (activeLoans.isEmpty) return 0.0;

    final totalInitial = getTotalActiveInitialAmount();
    if (totalInitial == 0) return 0.0;

    final totalRemaining = getTotalRemainingAmount();
    return ((totalInitial - totalRemaining) / totalInitial).clamp(0.0, 1.0);
  }
}
