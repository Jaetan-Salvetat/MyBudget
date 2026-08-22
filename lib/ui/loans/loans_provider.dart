import 'package:mybudget/core/entities/loan.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/loan_service.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'loans_provider.g.dart';

@Riverpod(keepAlive: true)
class LoanNotifier extends _$LoanNotifier {
  final LoanService _loanService = LoanService();

  @override
  Future<List<Loan>> build() async {
    final repo = ref.watch(loanRepositoryProvider);
    final models = repo.getAll();
    final loans = _loanService.createLoans(models);

    loans.sort((a, b) {
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      return b.startDate.compareTo(a.startDate);
    });

    return loans;
  }

  Future<void> addLoan(LoanModel loan) async {
    try {
      final repo = ref.read(loanRepositoryProvider);
      repo.add(loan);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateLoan(LoanModel loan) async {
    try {
      final repo = ref.read(loanRepositoryProvider);
      repo.update(loan);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteLoan(int id) async {
    try {
      final repo = ref.read(loanRepositoryProvider);
      repo.delete(id);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  List<Loan> _currentLoans() => state.value ?? [];

  List<Loan> getActiveLoans() =>
      _currentLoans().where((loan) => !loan.isCompleted).toList();

  List<Loan> getActiveLoansForAccount(int accountId) => _currentLoans()
      .where((loan) => loan.accountId == accountId && !loan.isCompleted)
      .toList();

  List<Loan> getCompletedLoans() =>
      _currentLoans().where((loan) => loan.isCompleted).toList();

  double getTotalRemainingAmount() =>
      getActiveLoans().fold(0.0, (sum, loan) => sum + loan.remainingCapital);

  double getTotalMonthlyPayments() => getActiveLoans().fold(
    0.0,
    (sum, loan) => sum + loan.currentMonthlyPayment,
  );

  double getTotalMonthlyPaymentsForAccount(int accountId) =>
      getActiveLoansForAccount(
        accountId,
      ).fold(0.0, (sum, loan) => sum + loan.currentMonthlyPayment);

  double getTotalActiveInitialAmount() =>
      getActiveLoans().fold(0.0, (sum, loan) => sum + loan.amount);

  double getTotalRemainingCost() =>
      getActiveLoans().fold(0.0, (sum, loan) => sum + loan.remainingCost);

  double getOverallProgressPercentage() {
    final activeLoans = getActiveLoans();
    if (activeLoans.isEmpty) return 0.0;

    final totalInitial = getTotalActiveInitialAmount();
    if (totalInitial == 0) return 0.0;

    final totalRemaining = getTotalRemainingAmount();
    return ((totalInitial - totalRemaining) / totalInitial).clamp(0.0, 1.0);
  }
}
