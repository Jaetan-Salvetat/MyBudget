import 'package:mybudget/core/values/loan_installment.dart';
import 'package:mybudget/core/values/loan_payment_breakdown.dart';

class LoanSchedule {
  const LoanSchedule({
    required this.installments,
    required this.borrowedAmount,
    this.fees = 0.0,
  });
  static const double _settledCapital = 0.005;

  final List<LoanInstallment> installments;
  final double borrowedAmount;
  final double fees;

  bool get isEmpty => installments.isEmpty;

  int get installmentCount => installments.length;

  DateTime? get startDate => isEmpty ? null : installments.first.date;

  DateTime? get endDate => isEmpty ? null : installments.last.date;

  double get totalInterest =>
      installments.fold(0.0, (sum, i) => sum + i.interest);

  double get totalInsurance =>
      installments.fold(0.0, (sum, i) => sum + i.insurance);

  double get totalIndemnity =>
      installments.fold(0.0, (sum, i) => sum + i.indemnity);

  double get totalPaid =>
      installments.fold(0.0, (sum, i) => sum + i.totalPayment);

  double get totalCost =>
      totalInterest + totalInsurance + totalIndemnity + fees;

  double get scheduledMonthlyPayment {
    for (final installment in installments) {
      if (installment.kind == LoanInstallmentKind.amortizing ||
          installment.kind == LoanInstallmentKind.interestOnly) {
        return installment.scheduledPayment;
      }
    }
    return isEmpty ? 0.0 : installments.first.scheduledPayment;
  }

  Iterable<LoanInstallment> settledAt(DateTime date) =>
      installments.where((i) => !i.date.isAfter(date));

  Iterable<LoanInstallment> pendingAt(DateTime date) =>
      installments.where((i) => i.date.isAfter(date));

  double remainingCapitalAt(DateTime date) {
    final settled = settledAt(date);
    return settled.isEmpty ? borrowedAmount : settled.last.closingCapital;
  }

  LoanInstallment? currentInstallmentAt(DateTime date) {
    for (final installment in installments) {
      if (installment.date.isAfter(date)) return installment;
    }
    return null;
  }

  double currentPaymentAt(DateTime date) =>
      currentInstallmentAt(date)?.scheduledPayment ?? 0.0;

  int remainingInstallmentsAt(DateTime date) => pendingAt(date).length;

  double paymentsInMonth(DateTime month) => installments
      .where(
        (installment) =>
            installment.date.year == month.year &&
            installment.date.month == month.month,
      )
      .fold(0.0, (sum, installment) => sum + installment.totalPayment);

  LoanPaymentBreakdown cumulativeAt(DateTime date) {
    var capital = 0.0;
    var interest = 0.0;
    var insurance = 0.0;
    var total = 0.0;

    for (final installment in settledAt(date)) {
      capital += installment.principal + installment.earlyPrincipal;
      interest += installment.interest;
      insurance += installment.insurance;
      total += installment.totalPayment;
    }

    return LoanPaymentBreakdown(
      capitalPayment: capital,
      interestPayment: interest,
      insurancePayment: insurance,
      totalPayment: total,
    );
  }

  double remainingCostAt(DateTime date) => pendingAt(
    date,
  ).fold(0.0, (sum, i) => sum + i.interest + i.insurance + i.indemnity);

  bool isCompletedAt(DateTime date) =>
      !isEmpty && remainingCapitalAt(date) <= _settledCapital;

  double progressAt(DateTime date) {
    if (borrowedAmount <= 0) return 0.0;
    final repaid = borrowedAmount - remainingCapitalAt(date);
    return (repaid / borrowedAmount).clamp(0.0, 1.0);
  }
}
