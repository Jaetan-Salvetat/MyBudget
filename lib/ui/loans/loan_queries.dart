import 'package:mybudget/core/entities/loan.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'loan_queries.g.dart';

/// Liste des prêts actifs (non remboursés).
@Riverpod(keepAlive: true)
List<Loan> activeLoans(Ref ref) {
  final loans = ref.watch(loanProvider).value ?? [];
  return loans.where((loan) => !loan.isCompleted).toList();
}

/// Somme mensuelle des mensualités des prêts actifs.
@Riverpod(keepAlive: true)
double totalMonthlyLoanPayments(Ref ref) {
  return ref
      .watch(activeLoansProvider)
      .fold(0.0, (sum, loan) => sum + loan.currentMonthlyPayment);
}

/// Somme du capital restant dû sur les prêts actifs.
@Riverpod(keepAlive: true)
double totalRemainingLoanAmount(Ref ref) {
  return ref
      .watch(activeLoansProvider)
      .fold(0.0, (sum, loan) => sum + loan.remainingCapital);
}

/// Coût restant total (intérêts + assurance) sur les prêts actifs.
@Riverpod(keepAlive: true)
double totalRemainingLoanCost(Ref ref) {
  return ref
      .watch(activeLoansProvider)
      .fold(0.0, (sum, loan) => sum + loan.remainingCost);
}

/// Pourcentage de remboursement global sur les prêts actifs (0.0 – 1.0).
@Riverpod(keepAlive: true)
double overallLoanProgressPercentage(Ref ref) {
  final active = ref.watch(activeLoansProvider);
  if (active.isEmpty) return 0.0;

  final totalInitial = active.fold(0.0, (sum, loan) => sum + loan.amount);
  if (totalInitial == 0) return 0.0;

  final totalRemaining = ref.watch(totalRemainingLoanAmountProvider);
  return ((totalInitial - totalRemaining) / totalInitial).clamp(0.0, 1.0);
}
