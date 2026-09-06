import 'dart:math';

import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_status.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/core/values/loan_event.dart';
import 'package:mybudget/core/values/loan_installment.dart';
import 'package:mybudget/core/values/loan_payment_breakdown.dart';
import 'package:mybudget/core/values/loan_schedule.dart';
import 'package:mybudget/core/values/loan_terms.dart';

class Loan {
  const Loan({
    required this.id,
    required this.name,
    required this.lenderName,
    required this.accountId,
    required this.notes,
    required this.purpose,
    required this.terms,
    required this.schedule,
    required this.contractualSchedule,
    required this.events,
    required this.annualPercentageRate,
    required this.asOf,
  });
  final int id;
  final String name;
  final String lenderName;
  final int accountId;
  final String? notes;
  final LoanPurpose purpose;
  final LoanTerms terms;
  final LoanSchedule schedule;
  final LoanSchedule contractualSchedule;
  final List<LoanEvent> events;
  final double annualPercentageRate;
  final DateTime asOf;

  double get amount => terms.amount;
  int get dayOfMonth => terms.dayOfMonth;
  DateTime get startDate => terms.startDate;
  double get interestRate => terms.annualInterestRate;
  int get duration => terms.durationInMonths;
  double get fees => terms.fees;
  CreditRegime get regime =>
      terms.regime ?? LoanTerms.defaultRegimeFor(terms.amount);
  bool get hasIndemnityClause => terms.hasIndemnityClause;
  LoanRepaymentType get repaymentType => terms.repaymentType;
  int get deferredMonths => terms.deferredMonths;
  LoanDeferralType get deferralType => terms.deferralType;
  double get insuranceValue => terms.insuranceValue;
  LoanInsuranceType get insuranceType => terms.insuranceType;
  InsuranceCalculationMode get insuranceCalculationMode =>
      terms.insuranceCalculationMode;
  bool get immediateFirstPayment => terms.immediateFirstPayment;

  List<LoanInstallment> get installments => schedule.installments;

  DateTime get endDate => schedule.endDate ?? terms.startDate;

  double get currentMonthlyPayment => schedule.currentPaymentAt(asOf);

  double get remainingCapital => schedule.remainingCapitalAt(asOf);

  double paymentsInMonth(DateTime month) => schedule.paymentsInMonth(month);

  int get remainingMonths => schedule.remainingInstallmentsAt(asOf);

  int get paidMonths => schedule.settledAt(asOf).length;

  double get totalPaidAmount => schedule.cumulativeAt(asOf).totalPayment;

  LoanPaymentBreakdown get cumulativePaymentBreakdown =>
      schedule.cumulativeAt(asOf);

  LoanPaymentBreakdown get currentPaymentBreakdown {
    final installment = schedule.currentInstallmentAt(asOf);
    if (installment == null) return const LoanPaymentBreakdown.zero();

    return LoanPaymentBreakdown(
      capitalPayment: installment.principal,
      interestPayment: installment.interest,
      insurancePayment: installment.insurance,
      totalPayment: installment.scheduledPayment,
    );
  }

  double get progressPercentage => schedule.progressAt(asOf);

  double get totalCost => schedule.totalCost;

  double get contractualCost => contractualSchedule.totalCost;

  double get remainingCost => schedule.remainingCostAt(asOf);

  double get totalIndemnity => schedule.totalIndemnity;

  bool get hasEarlyRepayment => events.isNotEmpty;

  double get costSaved => max(0.0, contractualCost - totalCost);

  int get monthsSaved =>
      max(0, contractualSchedule.installmentCount - schedule.installmentCount);

  bool get isCompleted => schedule.isCompletedAt(asOf);

  bool get isPending => !isCompleted && asOf.isBefore(startDate);

  bool get isActive => !isCompleted && !isPending;

  bool get isInDeferredPeriod =>
      schedule.currentInstallmentAt(asOf)?.isDeferred ?? false;

  LoanStatus getStatus() {
    if (isCompleted) return LoanStatus.completed;
    if (isPending) return LoanStatus.pending;
    return LoanStatus.partiallyPaid;
  }
}
