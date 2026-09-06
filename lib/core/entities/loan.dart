import 'dart:math';

import 'package:mybudget/core/entities/loan_event.dart';
import 'package:mybudget/core/entities/loan_installment.dart';
import 'package:mybudget/core/entities/loan_payment_breakdown.dart';
import 'package:mybudget/core/entities/loan_schedule.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/models/loan_model.dart';

class Loan {
  final LoanModel model;
  final LoanSchedule schedule;
  final LoanSchedule contractualSchedule;
  final List<LoanEvent> events;
  final double annualPercentageRate;
  final DateTime asOf;

  const Loan({
    required this.model,
    required this.schedule,
    required this.contractualSchedule,
    required this.events,
    required this.annualPercentageRate,
    required this.asOf,
  });

  int get id => model.id;
  String get name => model.name;
  double get amount => model.amount;
  String get lenderName => model.lenderName;
  int get accountId => model.accountId;
  String? get notes => model.notes;
  int get dayOfMonth => model.dayOfMonth;
  DateTime get startDate => model.startDate;
  double get interestRate => model.interestRate;
  int get duration => model.duration;
  double get fees => model.fees;
  LoanPurpose get purpose => model.purpose;
  CreditRegime get regime => model.regime;
  bool get hasIndemnityClause => model.hasIndemnityClause;
  LoanRepaymentType get repaymentType => model.repaymentType;
  int get deferredMonths => model.deferredMonths;
  LoanDeferralType get deferralType => model.deferralType;
  double get insuranceValue => model.insuranceValue;
  LoanInsuranceType get insuranceType => model.insuranceType;
  InsuranceCalculationMode get insuranceCalculationMode =>
      model.insuranceCalculationMode;
  bool get immediateFirstPayment => model.immediateFirstPayment;

  List<LoanInstallment> get installments => schedule.installments;

  DateTime get endDate => schedule.endDate ?? model.startDate;

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

  int get monthsSaved => max(
    0,
    contractualSchedule.installmentCount - schedule.installmentCount,
  );

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
