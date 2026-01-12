import 'dart:math';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';

/// Service responsable de tous les calculs financiers liés aux prêts
/// Suit le principe de Single Responsibility
/// Toutes les méthodes sont pures (pas d'effet de bord) pour faciliter les tests
class LoanCalculationService {
  const LoanCalculationService();

  /// Calcule la mensualité actuelle d'un prêt
  /// Prend en compte le type de prêt, le différé, et la date actuelle
  double calculateCurrentMonthlyPayment({
    required LoanRepaymentType repaymentType,
    required double amount,
    required double interestRate,
    required int durationInMonths,
    required DateTime startDate,
    required DateTime currentDate,
    required int deferredMonths,
    required LoanInsuranceType insuranceType,
    required double insuranceValue,
    required InsuranceCalculationMode insuranceCalcMode,
  }) {
    final monthsSinceStart = _calculateMonthsSinceStart(startDate, currentDate);

    // Période de différé : pas de paiement
    if (monthsSinceStart < deferredMonths) {
      return 0.0;
    }

    // Calcul du capital restant pour l'assurance CRD
    final remainingCapital = calculateRemainingCapital(
      repaymentType: repaymentType,
      amount: amount,
      interestRate: interestRate,
      durationInMonths: durationInMonths,
      startDate: startDate,
      currentDate: currentDate,
      deferredMonths: deferredMonths,
    );

    // Calcul du paiement de prêt (capital + intérêts) selon le type
    final loanPayment = repaymentType == LoanRepaymentType.inFine
        ? _calculateInFineMonthlyPayment(amount, interestRate)
        : _calculateAmortizableMonthlyPayment(
            amount,
            interestRate,
            durationInMonths - deferredMonths,
          );

    final insurancePayment = _calculateInsurancePayment(
      amount: amount,
      insuranceType: insuranceType,
      insuranceValue: insuranceValue,
      calculationMode: insuranceCalcMode,
      remainingCapital: remainingCapital,
    );

    return loanPayment + insurancePayment;
  }

  /// Calcule le capital restant dû
  double calculateRemainingCapital({
    required LoanRepaymentType repaymentType,
    required double amount,
    required double interestRate,
    required int durationInMonths,
    required DateTime startDate,
    required DateTime currentDate,
    required int deferredMonths,
  }) {
    // Avant le début : capital = montant total
    if (currentDate.isBefore(startDate)) {
      return amount;
    }

    final monthsSinceStart = _calculateMonthsSinceStart(startDate, currentDate);

    // Pendant le différé : capital = montant total
    if (monthsSinceStart < deferredMonths) {
      return amount;
    }

    // In fine : capital reste constant jusqu'à la fin
    if (repaymentType == LoanRepaymentType.inFine) {
      return amount;
    }

    // Amortissable : calcul avec formule d'amortissement
    final effectiveDuration = durationInMonths - deferredMonths;
    final effectiveMonthsPassed = monthsSinceStart - deferredMonths;

    return _calculateAmortizableRemainingCapital(
      amount: amount,
      interestRate: interestRate,
      durationInMonths: effectiveDuration,
      monthsPassed: effectiveMonthsPassed,
    );
  }

  /// Calcule le nombre de mois restants jusqu'à la fin du prêt
  int calculateRemainingMonths({
    required DateTime currentDate,
    required DateTime endDate,
    required DateTime startDate,
    required int durationInMonths,
  }) {
    if (currentDate.isAfter(endDate)) return 0;
    if (currentDate.isBefore(startDate)) return durationInMonths;

    final endYearMonth = endDate.year * 12 + endDate.month;
    final nowYearMonth = currentDate.year * 12 + currentDate.month;

    final diff = endYearMonth - nowYearMonth;
    return diff.clamp(0, durationInMonths);
  }

  /// Calcule le montant total payé depuis le début
  double calculateTotalPaidAmount({
    required DateTime startDate,
    required DateTime currentDate,
    required DateTime endDate,
    required int dayOfMonth,
    required int deferredMonths,
    required double monthlyPayment,
  }) {
    if (currentDate.isBefore(startDate)) {
      return 0.0;
    }

    final effectiveEndDate = currentDate.isAfter(endDate) ? endDate : currentDate;

    final startYearMonth = startDate.year * 12 + startDate.month - 1;
    final endYearMonth = effectiveEndDate.year * 12 + effectiveEndDate.month - 1;
    final daysPassed = effectiveEndDate.day >= dayOfMonth ? 1 : 0;

    final totalMonthsPassed = (endYearMonth - startYearMonth) + daysPassed;
    final effectiveMonthsPaid = (totalMonthsPassed - deferredMonths).clamp(0, double.infinity).toInt();

    return effectiveMonthsPaid * monthlyPayment;
  }

  // ============= Méthodes privées =============

  /// Calcule le paiement mensuel pour un prêt in fine
  /// Pour l'in fine, on ne paie QUE les intérêts chaque mois, le capital est payé à la fin
  double _calculateInFineMonthlyPayment(
    double amount,
    double interestRate,
  ) {
    return (amount * interestRate / 100) / 12;
  }

  /// Calcule le paiement mensuel pour un prêt amortissable (capital + intérêts)
  /// Utilise la formule d'annuité constante
  double _calculateAmortizableMonthlyPayment(
    double amount,
    double interestRate,
    int durationInMonths,
  ) {
    if (amount <= 0 || durationInMonths <= 0) return 0.0;
    if (interestRate == 0) return amount / durationInMonths;

    final monthlyRate = interestRate / 100 / 12;
    return amount * (monthlyRate / (1 - pow(1 + monthlyRate, -durationInMonths)));
  }

  /// Calcule le capital restant dû pour un prêt amortissable
  /// Utilise la formule de capital restant avec intérêts composés
  double _calculateAmortizableRemainingCapital({
    required double amount,
    required double interestRate,
    required int durationInMonths,
    required int monthsPassed,
  }) {
    if (monthsPassed <= 0) return amount;
    if (monthsPassed >= durationInMonths) return 0.0;

    if (interestRate == 0) {
      return amount - (amount / durationInMonths * monthsPassed);
    }

    final monthlyRate = interestRate / 100 / 12;
    final numerator = pow(1 + monthlyRate, durationInMonths) -
        pow(1 + monthlyRate, monthsPassed);
    final denominator = pow(1 + monthlyRate, durationInMonths) - 1;

    return amount * (numerator / denominator);
  }

  /// Calcule le paiement mensuel d'assurance
  double _calculateInsurancePayment({
    required double amount,
    required LoanInsuranceType insuranceType,
    required double insuranceValue,
    required InsuranceCalculationMode calculationMode,
    required double remainingCapital,
  }) {
    if (insuranceType == LoanInsuranceType.none || insuranceValue <= 0) {
      return 0.0;
    }

    if (insuranceType == LoanInsuranceType.fixed) {
      return insuranceValue;
    }

    // Pourcentage : selon le mode de calcul (CI ou CRD)
    final baseCapital = calculationMode == InsuranceCalculationMode.initialCapital
        ? amount
        : remainingCapital;

    return (baseCapital * (insuranceValue / 100)) / 12;
  }

  /// Calcule le nombre de mois écoulés depuis le début du prêt
  int _calculateMonthsSinceStart(DateTime startDate, DateTime currentDate) {
    return (currentDate.year - startDate.year) * 12 +
        currentDate.month -
        startDate.month;
  }
}
