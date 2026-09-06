import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/core/values/loan_installment.dart';
import 'package:mybudget/core/values/loan_schedule.dart';
import 'package:mybudget/core/values/loan_terms.dart';
import 'package:mybudget/data/model/loan_model.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/data/service/annual_percentage_rate_service.dart';
import 'package:mybudget/data/service/early_repayment_indemnity_service.dart';
import 'package:mybudget/data/service/loan_schedule_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'loan_creation_provider.g.dart';

enum DurationUnit { years, months }

class LoanCreationState {
  LoanCreationState({
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
    this.deferralType = LoanDeferralType.partial,
    this.fees = 0.0,
    this.purpose = LoanPurpose.other,
    this.hasIndemnityClause = true,
    this.insuranceType = LoanInsuranceType.none,
    this.insuranceValue = 0.0,
    this.insuranceCalcMode = InsuranceCalculationMode.initialCapital,
    this.immediateFirstPayment = false,
  });
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
  final LoanDeferralType deferralType;
  final double fees;
  final LoanPurpose purpose;
  final bool hasIndemnityClause;
  final LoanInsuranceType insuranceType;
  final double insuranceValue;
  final InsuranceCalculationMode insuranceCalcMode;
  final bool immediateFirstPayment;

  static const LoanScheduleService _scheduleService = LoanScheduleService(
    EarlyRepaymentIndemnityService(),
  );
  static const AnnualPercentageRateService _rateService =
      AnnualPercentageRateService();

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
    LoanDeferralType? deferralType,
    double? fees,
    LoanPurpose? purpose,
    bool? hasIndemnityClause,
    LoanInsuranceType? insuranceType,
    double? insuranceValue,
    InsuranceCalculationMode? insuranceCalcMode,
    bool? immediateFirstPayment,
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
      deferralType: deferralType ?? this.deferralType,
      fees: fees ?? this.fees,
      purpose: purpose ?? this.purpose,
      hasIndemnityClause: hasIndemnityClause ?? this.hasIndemnityClause,
      insuranceType: insuranceType ?? this.insuranceType,
      insuranceValue: insuranceValue ?? this.insuranceValue,
      insuranceCalcMode: insuranceCalcMode ?? this.insuranceCalcMode,
      immediateFirstPayment:
          immediateFirstPayment ?? this.immediateFirstPayment,
    );
  }

  int get totalSteps => 5;

  int get durationInMonths {
    return durationUnit == DurationUnit.years
        ? durationValue * 12
        : durationValue;
  }

  LoanTerms get terms => LoanTerms(
    amount: amount,
    annualInterestRate: interestRate,
    durationInMonths: durationInMonths,
    startDate: startDate,
    dayOfMonth: dayOfMonth,
    immediateFirstPayment: immediateFirstPayment,
    repaymentType: repaymentType,
    deferredMonths: effectiveDeferredMonths,
    deferralType: hasDeferredPeriod ? deferralType : LoanDeferralType.none,
    insuranceType: insuranceType,
    insuranceValue: insuranceValue,
    insuranceCalculationMode: insuranceCalcMode,
    fees: fees,
    regime: effectiveRegime,
    hasIndemnityClause: hasIndemnityClause,
  );

  int get effectiveDeferredMonths => hasDeferredPeriod ? deferredMonths : 0;

  CreditRegime get effectiveRegime =>
      purpose.fixedRegime ?? LoanTerms.defaultRegimeFor(amount);

  late final LoanSchedule schedule = _scheduleService.build(terms);

  late final double annualPercentageRate = _rateService.compute(
    schedule: schedule,
    originDate: startDate,
  );

  LoanInstallment? get _firstBilledInstallment =>
      schedule.installments.where((i) => !i.isDeferred).firstOrNull;

  DateTime get calculatedEndDate => schedule.endDate ?? startDate;

  double get monthlyPrincipalPayment {
    final installment = _firstBilledInstallment;
    if (installment == null) return 0.0;
    return installment.principal + installment.interest;
  }

  double get monthlyInsurancePayment =>
      _firstBilledInstallment?.insurance ?? 0.0;

  double get totalMonthlyPayment => schedule.scheduledMonthlyPayment;

  double get totalCost => schedule.totalCost;

  bool get isStep1Valid {
    return name.isNotEmpty &&
        lenderName.isNotEmpty &&
        amount > 0 &&
        selectedAccountId != -1;
  }

  bool get isStep2Valid =>
      durationInMonths > 0 &&
      durationInMonths <= LoanTerms.maxDurationInMonths &&
      interestRate >= 0 &&
      fees >= 0 &&
      fees < amount;

  bool get isStep3Valid =>
      !hasDeferredPeriod ||
      (deferredMonths > 0 && deferredMonths < durationInMonths);
  bool get isStep4Valid => true;

  bool get isValid =>
      isStep1Valid && isStep2Valid && isStep3Valid && isStep4Valid;

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
    return LoanCreationState(startDate: ref.watch(clockProvider)());
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

  void setDeferralType(LoanDeferralType type) =>
      state = state.copyWith(deferralType: type);

  void setPurpose(LoanPurpose purpose) {
    state = state.copyWith(
      purpose: purpose,
      repaymentType: purpose == LoanPurpose.bridge
          ? LoanRepaymentType.inFine
          : null,
      immediateFirstPayment: purpose == LoanPurpose.instalmentPlan
          ? true
          : null,
      hasIndemnityClause: purpose.waivesIndemnityByDefault ? false : null,
    );
  }

  void toggleIndemnityClause() =>
      state = state.copyWith(hasIndemnityClause: !state.hasIndemnityClause);

  void setFees(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    state = state.copyWith(fees: parsed);
  }

  void setStartDate(DateTime date) => state = state.copyWith(startDate: date);

  void setDayOfMonth(int day) =>
      state = state.copyWith(dayOfMonth: day.clamp(1, 31));

  void setDurationValue(String value) {
    final parsed = int.tryParse(value) ?? 0;
    state = state.copyWith(durationValue: parsed);
  }

  void setDurationUnit(DurationUnit unit) =>
      state = state.copyWith(durationUnit: unit);

  void setInterestRate(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    state = state.copyWith(interestRate: parsed);
  }

  void setRepaymentType(LoanRepaymentType type) =>
      state = state.copyWith(repaymentType: type);

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

  void setInsuranceType(LoanInsuranceType type) =>
      state = state.copyWith(insuranceType: type);

  void setInsuranceValue(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    state = state.copyWith(insuranceValue: parsed);
  }

  void setInsuranceCalculationMode(InsuranceCalculationMode mode) {
    state = state.copyWith(insuranceCalcMode: mode);
  }

  void toggleImmediateFirstPayment() {
    state = state.copyWith(immediateFirstPayment: !state.immediateFirstPayment);
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
      deferredMonths: state.effectiveDeferredMonths,
      deferralType: state.deferralType,
      fees: state.fees,
      purpose: state.purpose,
      hasIndemnityClause: state.hasIndemnityClause,
      insuranceType: state.insuranceType,
      insuranceValue: state.insuranceValue,
      insuranceCalculationMode: state.insuranceCalcMode,
      immediateFirstPayment: state.immediateFirstPayment,
    );
  }
}
