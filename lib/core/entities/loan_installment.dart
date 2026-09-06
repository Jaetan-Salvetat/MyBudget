import 'package:mybudget/core/utils/money.dart';

enum LoanInstallmentKind {
  deferredPartial,
  deferredTotal,
  amortizing,
  interestOnly,
  earlyRepayment,
}

class LoanInstallment {
  const LoanInstallment({
    required this.number,
    required this.date,
    required this.openingCapital,
    required this.interest,
    required this.insurance,
    required this.principal,
    required this.closingCapital,
    required this.kind,
    this.earlyPrincipal = 0.0,
    this.indemnity = 0.0,
  });
  final int number;
  final DateTime date;
  final double openingCapital;
  final double interest;
  final double insurance;
  final double principal;
  final double earlyPrincipal;
  final double indemnity;
  final double closingCapital;
  final LoanInstallmentKind kind;

  double get scheduledPayment => roundToCents(principal + interest + insurance);

  double get totalPayment =>
      roundToCents(scheduledPayment + earlyPrincipal + indemnity);

  bool get isDeferred =>
      kind == LoanInstallmentKind.deferredPartial ||
      kind == LoanInstallmentKind.deferredTotal;

  bool get hasEarlyRepayment => earlyPrincipal > 0;
}
