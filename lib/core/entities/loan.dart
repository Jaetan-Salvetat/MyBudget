import 'package:mybudget/core/entities/loan_payment_breakdown.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/core/services/loan_calculation_service.dart';
import 'package:mybudget/core/services/loan_payment_breakdown_service.dart';
import 'package:mybudget/models/loan_model.dart';

class Loan {
  final LoanModel _model;
  final LoanCalculationService _calculationService;
  final LoanPaymentBreakdownService _breakdownService;

  Loan(this._model, this._calculationService, this._breakdownService);

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
  InsuranceCalculationMode get insuranceCalculationMode =>
      _model.insuranceCalculationMode;
  bool get immediateFirstPayment => _model.immediateFirstPayment;

  LoanModel get model => _model;

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
      immediateFirstPayment: _model.immediateFirstPayment,
    );
  }

  double get remainingCapital {
    return _calculationService.calculateRemainingCapital(
      repaymentType: _model.repaymentType,
      amount: _model.amount,
      interestRate: _model.interestRate,
      durationInMonths: _model.duration,
      startDate: _model.startDate,
      currentDate: DateTime.now(),
      deferredMonths: _model.deferredMonths,
      immediateFirstPayment: _model.immediateFirstPayment,
    );
  }

  int get remainingMonths {
    return _calculationService.calculateRemainingMonths(
      currentDate: DateTime.now(),
      endDate: _model.endDate,
      startDate: _model.startDate,
      durationInMonths: _model.duration,
      immediateFirstPayment: _model.immediateFirstPayment,
    );
  }

  double get totalPaidAmount {
    return _calculationService.calculateTotalPaidAmount(
      startDate: _model.startDate,
      currentDate: DateTime.now(),
      endDate: _model.endDate,
      dayOfMonth: _model.dayOfMonth,
      deferredMonths: _model.deferredMonths,
      monthlyPayment: currentMonthlyPayment,
      immediateFirstPayment: _model.immediateFirstPayment,
    );
  }

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
      immediateFirstPayment: _model.immediateFirstPayment,
    );
  }

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
      immediateFirstPayment: _model.immediateFirstPayment,
    );
  }

  double get progressPercentage {
    if (_model.amount == 0) return 0.0;
    final paid = _model.amount - remainingCapital;
    return (paid / _model.amount).clamp(0.0, 1.0);
  }

  double get totalCost {
    final totalPayments = currentMonthlyPayment * _model.duration;
    return (totalPayments - _model.amount).clamp(0.0, double.infinity);
  }

  double get remainingCost {
    final totalFuturePayments = remainingMonths * currentMonthlyPayment;
    final remainingPrincipal = remainingCapital;
    final cost = totalFuturePayments - remainingPrincipal;
    return cost > 0 ? cost : 0.0;
  }

  bool get isCompleted {
    final now = DateTime.now();
    return now.isAfter(_model.endDate) || remainingCapital <= 0;
  }

  bool get isPending {
    return DateTime.now().isBefore(_model.startDate);
  }

  bool get isActive {
    return !isCompleted && !isPending;
  }

  bool get isInDeferredPeriod {
    if (_model.deferredMonths == 0) return false;

    final now = DateTime.now();
    if (now.isBefore(_model.startDate)) return false;

    final monthsSinceStart =
        (now.year - _model.startDate.year) * 12 +
        now.month -
        _model.startDate.month;

    return monthsSinceStart < _model.deferredMonths;
  }

  LoanStatus getStatus() {
    if (isCompleted) return LoanStatus.completed;
    if (isPending) return LoanStatus.pending;
    return LoanStatus.partiallyPaid;
  }

  static Loan fromModel(
    LoanModel model,
    LoanCalculationService calculationService,
    LoanPaymentBreakdownService breakdownService,
  ) {
    return Loan(model, calculationService, breakdownService);
  }
}
