import 'package:mybudget/core/services/loan_calculation_service.dart';
import 'package:mybudget/models/loan_model.dart';

/// Extensions temporaires sur LoanModel pour assurer la rétro-compatibilité
/// pendant la migration vers la nouvelle architecture
///
/// ⚠️ DEPRECATED - Ces méthodes seront supprimées une fois la migration terminée
/// Utilisez plutôt l'entité Loan via LoanService
extension LoanModelCompatibility on LoanModel {
  static const _calculationService = LoanCalculationService();

  /// Mensualité calculée dynamiquement
  @Deprecated('Use Loan.currentMonthlyPayment instead')
  double get monthlyPayment {
    return _calculationService.calculateCurrentMonthlyPayment(
      repaymentType: repaymentType,
      amount: amount,
      interestRate: interestRate,
      durationInMonths: duration,
      startDate: startDate,
      currentDate: DateTime.now(),
      deferredMonths: deferredMonths,
      insuranceType: insuranceType,
      insuranceValue: insuranceValue,
      insuranceCalcMode: insuranceCalculationMode,
    );
  }

  /// Capital restant dû
  @Deprecated('Use Loan.remainingCapital instead')
  double get remainingCapital {
    return _calculationService.calculateRemainingCapital(
      repaymentType: repaymentType,
      amount: amount,
      interestRate: interestRate,
      durationInMonths: duration,
      startDate: startDate,
      currentDate: DateTime.now(),
      deferredMonths: deferredMonths,
    );
  }

  /// Mois restants
  @Deprecated('Use Loan.remainingMonths instead')
  int get remainingMonths {
    return _calculationService.calculateRemainingMonths(
      currentDate: DateTime.now(),
      endDate: endDate,
      startDate: startDate,
      durationInMonths: duration,
    );
  }

  /// Coût total du crédit
  @Deprecated('Use Loan.totalCost instead')
  double get totalCost {
    final totalPayments = monthlyPayment * duration;
    return (totalPayments - amount).clamp(0.0, double.infinity);
  }

  /// Pourcentage de progression
  @Deprecated('Use Loan.progressPercentage instead')
  double getProgressPercentage() {
    if (amount == 0) return 0.0;
    final remaining = remainingCapital;
    return ((amount - remaining) / amount).clamp(0.0, 1.0);
  }

  /// Montant restant
  @Deprecated('Use Loan.remainingCapital instead')
  double getRemainingAmount() {
    return remainingCapital;
  }

  /// Prêt terminé ?
  @Deprecated('Use Loan.isCompleted instead')
  bool isCompleted() {
    final now = DateTime.now();
    return now.isAfter(endDate) || remainingCapital <= 0;
  }

  /// Statut automatique
  @Deprecated('Use Loan.getStatus() instead')
  LoanStatus getAutomaticStatus() {
    final now = DateTime.now();

    if (now.isAfter(endDate)) {
      return LoanStatus.completed;
    }

    if (remainingCapital <= 0) {
      return LoanStatus.completed;
    }

    if (now.isBefore(startDate)) {
      return LoanStatus.pending;
    }

    return LoanStatus.partiallyPaid;
  }

  /// Montant total payé
  @Deprecated('Use Loan.totalPaidAmount instead')
  double get totalPaidCash => getAutomaticPaidAmount();

  @Deprecated('Use Loan.totalPaidAmount instead')
  double getAutomaticPaidAmount() {
    return _calculationService.calculateTotalPaidAmount(
      startDate: startDate,
      currentDate: DateTime.now(),
      endDate: endDate,
      dayOfMonth: dayOfMonth,
      deferredMonths: deferredMonths,
      monthlyPayment: monthlyPayment,
    );
  }

  @Deprecated('Use Loan.totalPaidAmount instead')
  double get paidAmount => totalPaidCash;
}
