import 'dart:math';
import 'package:mybudget/core/enums/loan_enums.dart';

class LoanCalculator {
  static double calculatePrincipalPayment({
    required double amount,
    required double annualRate,
    required int durationInMonths,
  }) {
    if (amount <= 0 || durationInMonths <= 0) return 0.0;
    if (annualRate == 0) return amount / durationInMonths;

    final monthlyRate = annualRate / 100 / 12;
    return amount *
        (monthlyRate / (1 - pow(1 + monthlyRate, -durationInMonths)));
  }

  static double calculateMonthlyInsurance({
    required double amount,
    required LoanInsuranceType type,
    required double value,
  }) {
    if (value <= 0) return 0.0;

    switch (type) {
      case LoanInsuranceType.fixed:
        return value;
      case LoanInsuranceType.percentage:
        return (amount * (value / 100)) / 12;
      case LoanInsuranceType.none:
        return 0.0;
    }
  }

  static double calculateTotalMonthlyPayment({
    required double amount,
    required double annualRate,
    required int durationInMonths,
    required LoanInsuranceType insuranceType,
    required double insuranceValue,
  }) {
    final principalPayment = calculatePrincipalPayment(
      amount: amount,
      annualRate: annualRate,
      durationInMonths: durationInMonths,
    );

    final insurancePayment = calculateMonthlyInsurance(
      amount: amount,
      type: insuranceType,
      value: insuranceValue,
    );

    return principalPayment + insurancePayment;
  }

  static double calculateRemainingPrincipal({
    required double amount,
    required double annualRate,
    required int durationInMonths,
    required int monthsPassed,
  }) {
    if (monthsPassed <= 0) return amount;
    if (monthsPassed >= durationInMonths) return 0.0;
    if (annualRate == 0) {
      return amount - (amount / durationInMonths * monthsPassed);
    }

    final monthlyRate = annualRate / 100 / 12;

    final numerator =
        pow(1 + monthlyRate, durationInMonths) -
        pow(1 + monthlyRate, monthsPassed);
    final denominator = pow(1 + monthlyRate, durationInMonths) - 1;

    return amount * (numerator / denominator);
  }
}
