import 'package:mybudget/core/entities/loan.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'loan_queries.g.dart';

@Riverpod(keepAlive: true)
List<Loan> activeLoans(Ref ref) {
  final loans = ref.watch(loanProvider).value ?? [];
  return loans.where((loan) => !loan.isCompleted).toList();
}

@Riverpod(keepAlive: true)
double totalMonthlyLoanPayments(Ref ref) {
  return ref
      .watch(activeLoansProvider)
      .fold(0.0, (sum, loan) => sum + loan.currentMonthlyPayment);
}

@Riverpod(keepAlive: true)
double totalRemainingLoanAmount(Ref ref) {
  return ref
      .watch(activeLoansProvider)
      .fold(0.0, (sum, loan) => sum + loan.remainingCapital);
}
