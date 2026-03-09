import 'package:mybudget/core/entities/loan_payment_breakdown.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/core/services/loan_calculation_service.dart';
import 'package:mybudget/core/services/loan_payment_breakdown_service.dart';
import 'package:mybudget/models/loan_model.dart';

/// Entité métier représentant un prêt avec toute sa logique
/// Utilise le pattern Facade pour déléguer les calculs aux services
/// Responsabilité : exposer une API cohérente pour manipuler un prêt
class Loan {
  final LoanModel _model;
  final LoanCalculationService _calculationService;
  final LoanPaymentBreakdownService _breakdownService;

  Loan(
    this._model,
    this._calculationService,
    this._breakdownService,
  );

  // ============= Propriétés de base (délégation au model) =============

  int get id => _model.id;
  String get name => _model.name;
  double get amount => _model.amount;
  String get lenderName => _model.lenderName;
  int get accountId => _model.accountId;
  String? get notes => _model.notes;
  int get dayOfMonth => _model.dayOfMonth;
  DateTime get startDate => _model.startDate;
  DateTime get endDate => _model.endDate;
  double get interestRate => _model.interestRate;
  int get duration => _model.duration;
  LoanRepaymentType get repaymentType => _model.repaymentType;
  int get deferredMonths => _model.deferredMonths;
  double get insuranceValue => _model.insuranceValue;
  LoanInsuranceType get insuranceType => _model.insuranceType;
  InsuranceCalculationMode get insuranceCalculationMode => _model.insuranceCalculationMode;

  // Accès au model pour la persistance
  LoanModel get model => _model;

  // ============= Logique métier calculée via les services =============

  /// Mensualité actuelle (recalculée dynamiquement)
  double get currentMonthlyPayment {
    return _calculationService.calculateCurrentMonthlyPayment(
      repaymentType: _model.repaymentType,
      amount: _model.amount,
      interestRate: _model.interestRate,
      durationInMonths: _model.duration,
      startDate: _model.startDate,
      currentDate: DateTime.now(),
      deferredMonths: _model.deferredMonths,
      insuranceType: _model.insuranceType,
      insuranceValue: _model.insuranceValue,
      insuranceCalcMode: _model.insuranceCalculationMode,
    );
  }

  /// Capital restant dû
  double get remainingCapital {
    return _calculationService.calculateRemainingCapital(
      repaymentType: _model.repaymentType,
      amount: _model.amount,
      interestRate: _model.interestRate,
      durationInMonths: _model.duration,
      startDate: _model.startDate,
      currentDate: DateTime.now(),
      deferredMonths: _model.deferredMonths,
    );
  }

  /// Nombre de mois restants
  int get remainingMonths {
    return _calculationService.calculateRemainingMonths(
      currentDate: DateTime.now(),
      endDate: _model.endDate,
      startDate: _model.startDate,
      durationInMonths: _model.duration,
    );
  }

  /// Montant total payé depuis le début
  double get totalPaidAmount {
    return _calculationService.calculateTotalPaidAmount(
      startDate: _model.startDate,
      currentDate: DateTime.now(),
      endDate: _model.endDate,
      dayOfMonth: _model.dayOfMonth,
      deferredMonths: _model.deferredMonths,
      monthlyPayment: currentMonthlyPayment,
    );
  }

  /// Décomposition du paiement mensuel actuel
  LoanPaymentBreakdown get currentPaymentBreakdown {
    return _breakdownService.calculateCurrentBreakdown(
      repaymentType: _model.repaymentType,
      amount: _model.amount,
      interestRate: _model.interestRate,
      durationInMonths: _model.duration,
      startDate: _model.startDate,
      currentDate: DateTime.now(),
      deferredMonths: _model.deferredMonths,
      insuranceType: _model.insuranceType,
      insuranceValue: _model.insuranceValue,
      insuranceCalcMode: _model.insuranceCalculationMode,
    );
  }

  /// Décomposition des totaux cumulés
  LoanPaymentBreakdown get cumulativePaymentBreakdown {
    return _breakdownService.calculateCumulativeBreakdown(
      repaymentType: _model.repaymentType,
      amount: _model.amount,
      interestRate: _model.interestRate,
      durationInMonths: _model.duration,
      startDate: _model.startDate,
      currentDate: DateTime.now(),
      endDate: _model.endDate,
      dayOfMonth: _model.dayOfMonth,
      deferredMonths: _model.deferredMonths,
      insuranceType: _model.insuranceType,
      insuranceValue: _model.insuranceValue,
      insuranceCalcMode: _model.insuranceCalculationMode,
    );
  }

  /// Pourcentage de progression (0.0 à 1.0)
  double get progressPercentage {
    if (_model.amount == 0) return 0.0;
    final paid = _model.amount - remainingCapital;
    return (paid / _model.amount).clamp(0.0, 1.0);
  }

  /// Coût total du crédit (intérêts + assurance)
  double get totalCost {
    final totalPayments = currentMonthlyPayment * _model.duration;
    return (totalPayments - _model.amount).clamp(0.0, double.infinity);
  }

  /// Coût restant du crédit
  double get remainingCost {
    final totalFuturePayments = remainingMonths * currentMonthlyPayment;
    final remainingPrincipal = remainingCapital;
    final cost = totalFuturePayments - remainingPrincipal;
    return cost > 0 ? cost : 0.0;
  }

  // ============= États et statuts =============

  /// Prêt terminé ?
  bool get isCompleted {
    final now = DateTime.now();
    return now.isAfter(_model.endDate) || remainingCapital <= 0;
  }

  /// Prêt pas encore commencé ?
  bool get isPending {
    return DateTime.now().isBefore(_model.startDate);
  }

  /// Prêt en cours ?
  bool get isActive {
    return !isCompleted && !isPending;
  }

  /// En période de différé ?
  bool get isInDeferredPeriod {
    if (_model.deferredMonths == 0) return false;

    final now = DateTime.now();
    if (now.isBefore(_model.startDate)) return false;

    final monthsSinceStart = (now.year - _model.startDate.year) * 12 +
        now.month -
        _model.startDate.month;

    return monthsSinceStart < _model.deferredMonths;
  }

  /// Statut du prêt
  LoanStatus getStatus() {
    if (isCompleted) return LoanStatus.completed;
    if (isPending) return LoanStatus.pending;
    return LoanStatus.partiallyPaid;
  }

  // ============= Helpers =============

  /// Crée une instance Loan à partir d'un LoanModel
  /// Factory pattern pour l'injection des dépendances
  static Loan fromModel(
    LoanModel model,
    LoanCalculationService calculationService,
    LoanPaymentBreakdownService breakdownService,
  ) {
    return Loan(model, calculationService, breakdownService);
  }
}
