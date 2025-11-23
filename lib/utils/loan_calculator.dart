import 'dart:math';
import 'package:mybudget/core/enums/loan_enums.dart';

class LoanCalculator {
  /// Calcule la mensualité du crédit (hors assurance)
  /// Formule: M = C * (r / (1 - (1 + r)^-n))
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

  /// Calcule le coût mensuel de l'assurance
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
        // Taux annuel sur le capital initial divisé par 12
        return (amount * (value / 100)) / 12;
      case LoanInsuranceType.none:
        return 0.0;
    }
  }

  /// Calcule le total mensuel (Crédit + Assurance)
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
}
