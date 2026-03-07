import 'package:mybudget/core/domain/loan_payment_breakdown.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/core/services/loan_calculation_service.dart';

/// Service pour calculer la répartition détaillée des paiements d'un prêt
/// Sépare clairement la logique de breakdown de la logique de calcul pure
class LoanPaymentBreakdownService {
  final LoanCalculationService _calculationService;

  const LoanPaymentBreakdownService(this._calculationService);

  /// Calcule la décomposition du paiement mensuel actuel
  LoanPaymentBreakdown calculateCurrentBreakdown({
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

    // Pendant le différé : pas de paiement
    if (monthsSinceStart < deferredMonths) {
      return const LoanPaymentBreakdown.zero();
    }

    final remainingCapital = _calculationService.calculateRemainingCapital(
      repaymentType: repaymentType,
      amount: amount,
      interestRate: interestRate,
      durationInMonths: durationInMonths,
      startDate: startDate,
      currentDate: currentDate,
      deferredMonths: deferredMonths,
    );

    final interestPayment = _calculateCurrentInterestPayment(
      repaymentType: repaymentType,
      amount: amount,
      remainingCapital: remainingCapital,
      interestRate: interestRate,
    );

    final insurancePayment = _calculateCurrentInsurancePayment(
      amount: amount,
      insuranceType: insuranceType,
      insuranceValue: insuranceValue,
      calculationMode: insuranceCalcMode,
      remainingCapital: remainingCapital,
    );

    final totalPayment = _calculationService.calculateCurrentMonthlyPayment(
      repaymentType: repaymentType,
      amount: amount,
      interestRate: interestRate,
      durationInMonths: durationInMonths,
      startDate: startDate,
      currentDate: currentDate,
      deferredMonths: deferredMonths,
      insuranceType: insuranceType,
      insuranceValue: insuranceValue,
      insuranceCalcMode: insuranceCalcMode,
    );

    // Pour in fine : pas de capital dans la mensualité
    final capitalPayment = repaymentType == LoanRepaymentType.inFine
        ? 0.0
        : totalPayment - interestPayment - insurancePayment;

    return LoanPaymentBreakdown(
      capitalPayment: capitalPayment,
      interestPayment: interestPayment,
      insurancePayment: insurancePayment,
      totalPayment: totalPayment,
    );
  }

  /// Calcule les totaux cumulés payés depuis le début du prêt
  LoanPaymentBreakdown calculateCumulativeBreakdown({
    required LoanRepaymentType repaymentType,
    required double amount,
    required double interestRate,
    required int durationInMonths,
    required DateTime startDate,
    required DateTime currentDate,
    required DateTime endDate,
    required int dayOfMonth,
    required int deferredMonths,
    required LoanInsuranceType insuranceType,
    required double insuranceValue,
    required InsuranceCalculationMode insuranceCalcMode,
  }) {
    if (currentDate.isBefore(startDate)) {
      return const LoanPaymentBreakdown.zero();
    }

    final monthlyPayment = _calculationService.calculateCurrentMonthlyPayment(
      repaymentType: repaymentType,
      amount: amount,
      interestRate: interestRate,
      durationInMonths: durationInMonths,
      startDate: startDate,
      currentDate: currentDate,
      deferredMonths: deferredMonths,
      insuranceType: insuranceType,
      insuranceValue: insuranceValue,
      insuranceCalcMode: insuranceCalcMode,
    );

    final totalPaid = _calculationService.calculateTotalPaidAmount(
      startDate: startDate,
      currentDate: currentDate,
      endDate: endDate,
      dayOfMonth: dayOfMonth,
      deferredMonths: deferredMonths,
      monthlyPayment: monthlyPayment,
    );

    final remainingCapital = _calculationService.calculateRemainingCapital(
      repaymentType: repaymentType,
      amount: amount,
      interestRate: interestRate,
      durationInMonths: durationInMonths,
      startDate: startDate,
      currentDate: currentDate,
      deferredMonths: deferredMonths,
    );

    final capitalPaid = amount - remainingCapital;

    // Calcul de l'assurance totale payée
    final insurancePaid = _calculateCumulativeInsurance(
      startDate: startDate,
      currentDate: currentDate,
      deferredMonths: deferredMonths,
      amount: amount,
      insuranceType: insuranceType,
      insuranceValue: insuranceValue,
      calculationMode: insuranceCalcMode,
      repaymentType: repaymentType,
      interestRate: interestRate,
      durationInMonths: durationInMonths,
    );

    final interestsPaid = totalPaid - capitalPaid - insurancePaid;

    return LoanPaymentBreakdown(
      capitalPayment: capitalPaid,
      interestPayment: interestsPaid,
      insurancePayment: insurancePaid,
      totalPayment: totalPaid,
    );
  }

  // ============= Méthodes privées =============

  /// Calcule le paiement d'intérêts du mois actuel
  double _calculateCurrentInterestPayment({
    required LoanRepaymentType repaymentType,
    required double amount,
    required double remainingCapital,
    required double interestRate,
  }) {
    // In fine : intérêts calculés sur le capital total
    // Amortissable : intérêts calculés sur le capital restant
    final baseCapital = repaymentType == LoanRepaymentType.inFine
        ? amount
        : remainingCapital;

    return (baseCapital * interestRate / 100) / 12;
  }

  /// Calcule le paiement d'assurance du mois actuel
  double _calculateCurrentInsurancePayment({
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

    // Pourcentage : selon le mode de calcul
    final baseCapital = calculationMode == InsuranceCalculationMode.initialCapital
        ? amount
        : remainingCapital;

    return (baseCapital * (insuranceValue / 100)) / 12;
  }

  /// Calcule l'assurance totale payée depuis le début
  /// Pour l'assurance sur CRD, il faut intégrer mois par mois
  double _calculateCumulativeInsurance({
    required DateTime startDate,
    required DateTime currentDate,
    required int deferredMonths,
    required double amount,
    required LoanInsuranceType insuranceType,
    required double insuranceValue,
    required InsuranceCalculationMode calculationMode,
    required LoanRepaymentType repaymentType,
    required double interestRate,
    required int durationInMonths,
  }) {
    if (insuranceType == LoanInsuranceType.none || insuranceValue <= 0) {
      return 0.0;
    }

    final monthsSinceStart = _calculateMonthsSinceStart(startDate, currentDate);
    final effectiveMonthsPaid = (monthsSinceStart - deferredMonths).clamp(0, double.infinity).toInt();

    if (effectiveMonthsPaid <= 0) return 0.0;

    // Assurance fixe : simple multiplication
    if (insuranceType == LoanInsuranceType.fixed) {
      return insuranceValue * effectiveMonthsPaid;
    }

    // Assurance sur capital initial : mensualité constante
    if (calculationMode == InsuranceCalculationMode.initialCapital) {
      final monthlyInsurance = (amount * (insuranceValue / 100)) / 12;
      return monthlyInsurance * effectiveMonthsPaid;
    }

    // Assurance sur capital restant dû : faut intégrer mois par mois
    // Simplifié : on fait une approximation avec la moyenne
    final initialMonthly = (amount * (insuranceValue / 100)) / 12;

    final currentRemaining = _calculationService.calculateRemainingCapital(
      repaymentType: repaymentType,
      amount: amount,
      interestRate: interestRate,
      durationInMonths: durationInMonths,
      startDate: startDate,
      currentDate: currentDate,
      deferredMonths: deferredMonths,
    );

    final currentMonthly = (currentRemaining * (insuranceValue / 100)) / 12;

    // Moyenne arithmétique (approximation acceptable)
    final averageMonthly = (initialMonthly + currentMonthly) / 2;
    return averageMonthly * effectiveMonthsPaid;
  }

  int _calculateMonthsSinceStart(DateTime startDate, DateTime currentDate) {
    return (currentDate.year - startDate.year) * 12 +
        currentDate.month -
        startDate.month;
  }
}
