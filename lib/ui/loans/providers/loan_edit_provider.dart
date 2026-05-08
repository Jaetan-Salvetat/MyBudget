import 'package:mybudget/core/entities/loan.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'loan_edit_provider.g.dart';

class LoanEditState {
  final Loan initialLoan;
  final String name;
  final String lenderName;
  final int selectedAccountId;
  final int dayOfMonth;
  final LoanInsuranceType insuranceType;
  final double insuranceValue;
  final InsuranceCalculationMode insuranceCalcMode;

  const LoanEditState({
    required this.initialLoan,
    required this.name,
    required this.lenderName,
    required this.selectedAccountId,
    required this.dayOfMonth,
    required this.insuranceType,
    required this.insuranceValue,
    required this.insuranceCalcMode,
  });

  factory LoanEditState.fromLoan(Loan loan) {
    return LoanEditState(
      initialLoan: loan,
      name: loan.name,
      lenderName: loan.lenderName,
      selectedAccountId: loan.accountId,
      dayOfMonth: loan.dayOfMonth,
      insuranceType: loan.insuranceType,
      insuranceValue: loan.insuranceValue,
      insuranceCalcMode: loan.insuranceCalculationMode,
    );
  }

  LoanEditState copyWith({
    String? name,
    String? lenderName,
    int? selectedAccountId,
    int? dayOfMonth,
    LoanInsuranceType? insuranceType,
    double? insuranceValue,
    InsuranceCalculationMode? insuranceCalcMode,
  }) {
    return LoanEditState(
      initialLoan: initialLoan,
      name: name ?? this.name,
      lenderName: lenderName ?? this.lenderName,
      selectedAccountId: selectedAccountId ?? this.selectedAccountId,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      insuranceType: insuranceType ?? this.insuranceType,
      insuranceValue: insuranceValue ?? this.insuranceValue,
      insuranceCalcMode: insuranceCalcMode ?? this.insuranceCalcMode,
    );
  }

  double get capital => initialLoan.amount;
  DateTime get signatureDate => initialLoan.startDate;
  DateTime get endDate => initialLoan.endDate;
  int get duration => initialLoan.duration;
  double get interestRate => initialLoan.interestRate;
  LoanRepaymentType get repaymentType => initialLoan.repaymentType;
  int get deferredMonths => initialLoan.deferredMonths;
  bool get immediateFirstPayment => initialLoan.immediateFirstPayment;

  double get monthlyInsurancePayment {
    if (insuranceType == LoanInsuranceType.none || insuranceValue <= 0) {
      return 0.0;
    }
    if (insuranceType == LoanInsuranceType.fixed) {
      return insuranceValue;
    }
    return (capital * (insuranceValue / 100)) / 12;
  }

  bool get isValid {
    return name.trim().isNotEmpty &&
        lenderName.trim().isNotEmpty &&
        selectedAccountId > 0;
  }
}

@Riverpod(keepAlive: false)
Loan loanToEdit(Ref ref) => throw UnimplementedError(
  'loanToEditProvider must be overridden via ProviderScope',
);

@Riverpod(keepAlive: false, dependencies: [loanToEdit])
class LoanEditNotifier extends _$LoanEditNotifier {
  @override
  LoanEditState build() {
    final loan = ref.watch(loanToEditProvider);
    return LoanEditState.fromLoan(loan);
  }

  void setName(String value) => state = state.copyWith(name: value);
  void setLenderName(String value) => state = state.copyWith(lenderName: value);
  void setAccountId(int id) => state = state.copyWith(selectedAccountId: id);
  void setDayOfMonth(int day) => state = state.copyWith(dayOfMonth: day.clamp(1, 31));

  void setInsuranceType(LoanInsuranceType type) {
    state = state.copyWith(insuranceType: type);
  }

  void setInsuranceValue(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    state = state.copyWith(insuranceValue: parsed);
  }

  void setInsuranceCalculationMode(InsuranceCalculationMode mode) {
    state = state.copyWith(insuranceCalcMode: mode);
  }

  LoanModel createUpdatedLoanModel() {
    return state.initialLoan.model.copyWith(
      name: state.name.trim(),
      lenderName: state.lenderName.trim(),
      accountId: state.selectedAccountId,
      dayOfMonth: state.dayOfMonth,
      insuranceType: state.insuranceType,
      insuranceValue: state.insuranceValue,
      insuranceCalculationMode: state.insuranceCalcMode,
    );
  }
}
