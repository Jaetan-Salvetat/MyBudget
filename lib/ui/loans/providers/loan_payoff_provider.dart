import 'package:mybudget/core/entities/early_repayment_quote.dart';
import 'package:mybudget/core/entities/loan.dart';
import 'package:mybudget/core/entities/loan_event.dart';
import 'package:mybudget/core/enums/loan_event_types.dart';
import 'package:mybudget/core/services/early_repayment_indemnity_service.dart';
import 'package:mybudget/core/services/loan_payoff_service.dart';
import 'package:mybudget/core/services/loan_schedule_service.dart';
import 'package:mybudget/models/loan_event_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'loan_payoff_provider.g.dart';

class LoanPayoffState {
  LoanPayoffState({
    required this.loan,
    required this.date,
    this.type = LoanEventType.earlyRepaymentTotal,
    this.amount = 0.0,
    this.reamortizationMode = ReamortizationMode.reduceDuration,
    this.exemption = EarlyRepaymentExemption.none,
  });
  static const LoanPayoffService _payoffService = LoanPayoffService(
    LoanScheduleService(EarlyRepaymentIndemnityService()),
  );

  final Loan loan;
  final LoanEventType type;
  final DateTime date;
  final double amount;
  final ReamortizationMode reamortizationMode;
  final EarlyRepaymentExemption exemption;

  LoanPayoffState copyWith({
    LoanEventType? type,
    DateTime? date,
    double? amount,
    ReamortizationMode? reamortizationMode,
    EarlyRepaymentExemption? exemption,
  }) {
    return LoanPayoffState(
      loan: loan,
      type: type ?? this.type,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      reamortizationMode: reamortizationMode ?? this.reamortizationMode,
      exemption: exemption ?? this.exemption,
    );
  }

  bool get isTotal => type == LoanEventType.earlyRepaymentTotal;

  LoanEvent get event => LoanEvent(
    type: type,
    date: date,
    amount: amount,
    reamortizationMode: reamortizationMode,
    exemption: exemption,
  );

  late final EarlyRepaymentQuote? quote = _payoffService.quote(
    loan: loan,
    event: event,
  );

  bool get isValid => quote != null;

  LoanEventModel toEventModel() => LoanEventModel.create(
    loanId: loan.id,
    type: type,
    date: date,
    amount: amount,
    reamortizationMode: reamortizationMode,
    exemption: exemption,
  );
}

@Riverpod(keepAlive: false)
class LoanPayoffNotifier extends _$LoanPayoffNotifier {
  @override
  LoanPayoffState build(Loan loan) =>
      LoanPayoffState(loan: loan, date: _defaultDate(loan));

  DateTime _defaultDate(Loan loan) {
    final next = loan.schedule.currentInstallmentAt(loan.asOf);
    return next?.date ?? loan.asOf;
  }

  void setType(LoanEventType type) => state = state.copyWith(type: type);

  void setDate(DateTime date) => state = state.copyWith(date: date);

  void setAmount(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    state = state.copyWith(amount: parsed);
  }

  void setReamortizationMode(ReamortizationMode mode) =>
      state = state.copyWith(reamortizationMode: mode);

  void setExemption(EarlyRepaymentExemption exemption) =>
      state = state.copyWith(exemption: exemption);
}
