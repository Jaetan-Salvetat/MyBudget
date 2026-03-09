import 'package:mybudget/ui/expenses/expense_queries.dart';
import 'package:mybudget/ui/loans/loan_queries.dart';
import 'package:mybudget/ui/revenues/revenue_queries.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_queries.g.dart';

/// Cash-flow mensuel net = revenus mensuels − (dépenses mensuelles + mensualités prêts).
@Riverpod(keepAlive: true)
double netCashFlow(Ref ref) {
  final monthlyRev = ref.watch(monthlyRevenuesProvider);
  final monthlyExp = ref.watch(monthlyExpensesProvider);
  final monthlyLoans = ref.watch(totalMonthlyLoanPaymentsProvider);
  return monthlyRev - (monthlyExp + monthlyLoans);
}

/// Taux d'épargne mensuel en pourcentage (0 si revenus ≤ 0).
@Riverpod(keepAlive: true)
double savingsRate(Ref ref) {
  final revenues = ref.watch(monthlyRevenuesProvider);
  if (revenues <= 0) return 0.0;
  return (ref.watch(netCashFlowProvider) / revenues) * 100;
}

/// Total des dépenses mensuelles + mensualités prêts actifs.
@Riverpod(keepAlive: true)
double totalMonthlyOutflows(Ref ref) {
  return ref.watch(monthlyExpensesProvider) +
      ref.watch(totalMonthlyLoanPaymentsProvider);
}
