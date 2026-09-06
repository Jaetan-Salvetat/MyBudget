import 'dart:math';

import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';

class LoanTerms {
  static const int maxDurationInMonths = 600;
  static const double mortgageRegimeThreshold = 75000;

  final double amount;
  final double annualInterestRate;
  final int durationInMonths;
  final DateTime startDate;
  final int dayOfMonth;
  final bool immediateFirstPayment;
  final LoanRepaymentType repaymentType;
  final int deferredMonths;
  final LoanDeferralType deferralType;
  final LoanInsuranceType insuranceType;
  final double insuranceValue;
  final InsuranceCalculationMode insuranceCalculationMode;
  final double fees;
  final CreditRegime? regime;
  final bool hasIndemnityClause;

  const LoanTerms({
    required this.amount,
    required this.annualInterestRate,
    required this.durationInMonths,
    required this.startDate,
    required this.dayOfMonth,
    this.immediateFirstPayment = false,
    this.repaymentType = LoanRepaymentType.amortizable,
    this.deferredMonths = 0,
    this.deferralType = LoanDeferralType.none,
    this.insuranceType = LoanInsuranceType.none,
    this.insuranceValue = 0.0,
    this.insuranceCalculationMode = InsuranceCalculationMode.initialCapital,
    this.fees = 0.0,
    this.regime,
    this.hasIndemnityClause = true,
  });

  static CreditRegime defaultRegimeFor(double amount) =>
      amount > mortgageRegimeThreshold
      ? CreditRegime.mortgage
      : CreditRegime.consumer;

  CreditRegime get effectiveRegime => regime ?? defaultRegimeFor(amount);

  double get effectiveAnnualInterestRate =>
      annualInterestRate.isFinite && annualInterestRate > 0
      ? annualInterestRate
      : 0.0;

  double get monthlyInterestRate => effectiveAnnualInterestRate / 100 / 12;

  int get effectiveDuration => durationInMonths.clamp(0, maxDurationInMonths);

  int get effectiveDeferredMonths {
    if (deferralType == LoanDeferralType.none) return 0;
    return deferredMonths.clamp(0, max(0, effectiveDuration - 1));
  }

  int get amortizingMonths => effectiveDuration - effectiveDeferredMonths;
}
