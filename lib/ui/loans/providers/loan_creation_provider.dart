import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/core/services/loan_calculation_service.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'loan_creation_provider.g.dart';

enum DurationUnit { years, months }

class LoanCreationState {
  final int currentStep;
  final String name;
  final String lenderName;
  final double amount;
  final int selectedAccountId;
  final DateTime startDate;
  final int dayOfMonth;
  final int durationValue;
  final DurationUnit durationUnit;
  final double interestRate;
  final LoanRepaymentType repaymentType;
  final int deferredMonths;
  final bool hasDeferredPeriod;
  final LoanInsuranceType insuranceType;
  final double insuranceValue;
  final InsuranceCalculationMode insuranceCalcMode;

  const LoanCreationState({
    this.currentStep = 0,
    this.name = '',
    this.lenderName = '',
    this.amount = 0.0,
    this.selectedAccountId = -1,
    required this.startDate,
    this.dayOfMonth = 1,
    this.durationValue = 0,
    this.durationUnit = DurationUnit.years,
    this.interestRate = 0.0,
    this.repaymentType = LoanRepaymentType.amortizable,
    this.deferredMonths = 0,
    this.hasDeferredPeriod = false,
    this.insuranceType = LoanInsuranceType.none,
    this.insuranceValue = 0.0,
    this.insuranceCalcMode = InsuranceCalculationMode.initialCapital,
  });

  LoanCreationState copyWith({
    int? currentStep,
    String? name,
    String? lenderName,
    double? amount,
    int? selectedAccountId,
    DateTime? startDate,
    int? dayOfMonth,
    int? durationValue,
    DurationUnit? durationUnit,
    double? interestRate,
    LoanRepaymentType? repaymentType,
    int? deferredMonths,
    bool? hasDeferredPeriod,
    LoanInsuranceType? insuranceType,
    double? insuranceValue,
    InsuranceCalculationMode? insuranceCalcMode,
  }) {
    return LoanCreationState(
      currentStep: currentStep ?? this.currentStep,
      name: name ?? this.name,
      lenderName: lenderName ?? this.lenderName,
      amount: amount ?? this.amount,
      selectedAccountId: selectedAccountId ?? this.selectedAccountId,
      startDate: startDate ?? this.startDate,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      durationValue: durationValue ?? this.durationValue,
      durationUnit: durationUnit ?? this.durationUnit,
      interestRate: interestRate ?? this.interestRate,
      repaymentType: repaymentType ?? this.repaymentType,
      deferredMonths: deferredMonths ?? this.deferredMonths,
      hasDeferredPeriod: hasDeferredPeriod ?? this.hasDeferredPeriod,
      insuranceType: insuranceType ?? this.insuranceType,
      insuranceValue: insuranceValue ?? this.insuranceValue,
      insuranceCalcMode: insuranceCalcMode ?? this.insuranceCalcMode,
    );
  }

  int get totalSteps => 5;

  int get durationInMonths {
    return durationUnit == DurationUnit.years ? durationValue * 12 : durationValue;
  }

  DateTime get calculatedEndDate {
    final months = durationInMonths;
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    return DateTime(
      startDate.year + years,
      startDate.month + remainingMonths,
      startDate.day,
    );
  }

  double get monthlyPrincipalPayment {
    const calc = LoanCalculationService();
    if (repaymentType == LoanRepaymentType.inFine) {
      return (amount * interestRate / 100) / 12;
    }
    return calc.calculateCurrentMonthlyPayment(
      repaymentType: repaymentType,
      amount: amount,
      interestRate: interestRate,
      durationInMonths: durationInMonths - deferredMonths,
      startDate: startDate,
      currentDate: startDate,
      deferredMonths: 0,
      insuranceType: LoanInsuranceType.none,
      insuranceValue: 0,
      insuranceCalcMode: InsuranceCalculationMode.initialCapital,
    );
  }

  double get monthlyInsurancePayment {
    if (insuranceType == LoanInsuranceType.none || insuranceValue <= 0) {
      return 0.0;
    }
    if (insuranceType == LoanInsuranceType.fixed) {
      return insuranceValue;
    }
    return (amount * (insuranceValue / 100)) / 12;
  }

  double get totalMonthlyPayment => monthlyPrincipalPayment + monthlyInsurancePayment;

  bool get isStep1Valid {
    return name.isNotEmpty && lenderName.isNotEmpty && amount > 0 && selectedAccountId != -1;
  }

  bool get isStep2Valid => durationInMonths > 0 && interestRate >= 0;
  bool get isStep3Valid => true;
  bool get isStep4Valid => true;

  bool get isValid => isStep1Valid && isStep2Valid && isStep3Valid && isStep4Valid;

  bool get canGoNext {
    if (currentStep == 0) return isStep1Valid;
    if (currentStep == 1) return isStep2Valid;
    if (currentStep == 2) return isStep3Valid;
    if (currentStep == 3) return isStep4Valid;
    return false;
  }
}

@Riverpod(keepAlive: false)
class LoanCreationNotifier extends _$LoanCreationNotifier {
  @override
  LoanCreationState build() {
    return LoanCreationState(startDate: DateTime.now());
  }

  void nextStep() {
    if (state.currentStep < state.totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < state.totalSteps) {
      state = state.copyWith(currentStep: step);
    }
  }

  void setName(String value) => state = state.copyWith(name: value);
  void setLenderName(String value) => state = state.copyWith(lenderName: value);

  void setAmount(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    state = state.copyWith(amount: parsed);
  }

  void setAccountId(int id) => state = state.copyWith(selectedAccountId: id);

  void setStartDate(DateTime date) => state = state.copyWith(startDate: date);

  void setDayOfMonth(int day) => state = state.copyWith(dayOfMonth: day.clamp(1, 31));

  void setDurationValue(String value) {
    final parsed = int.tryParse(value) ?? 0;
    state = state.copyWith(durationValue: parsed);
  }

  void setDurationUnit(DurationUnit unit) => state = state.copyWith(durationUnit: unit);

  void setInterestRate(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    state = state.copyWith(interestRate: parsed);
  }

  void setRepaymentType(LoanRepaymentType type) => state = state.copyWith(repaymentType: type);

  void toggleDeferredPeriod() {
    final newValue = !state.hasDeferredPeriod;
    state = state.copyWith(
      hasDeferredPeriod: newValue,
      deferredMonths: newValue ? state.deferredMonths : 0,
    );
  }

  void setDeferredMonths(String value) {
    final parsed = int.tryParse(value) ?? 0;
    state = state.copyWith(deferredMonths: parsed);
  }

  void setInsuranceType(LoanInsuranceType type) => state = state.copyWith(insuranceType: type);

  void setInsuranceValue(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    state = state.copyWith(insuranceValue: parsed);
  }

  void setInsuranceCalculationMode(InsuranceCalculationMode mode) {
    state = state.copyWith(insuranceCalcMode: mode);
  }

  LoanModel createLoanModel() {
    return LoanModel.create(
      name: state.name,
      amount: state.amount,
      lenderName: state.lenderName,
      accountId: state.selectedAccountId,
      dayOfMonth: state.dayOfMonth,
      startDate: state.startDate,
      endDate: state.calculatedEndDate,
      interestRate: state.interestRate,
      duration: state.durationInMonths,
      repaymentType: state.repaymentType,
      deferredMonths: state.hasDeferredPeriod ? state.deferredMonths : 0,
      insuranceType: state.insuranceType,
      insuranceValue: state.insuranceValue,
      insuranceCalculationMode: state.insuranceCalcMode,
    );
  }
}
