import 'package:mybudget/core/enums/loan_event_types.dart';

class LoanEvent {
  final int id;
  final LoanEventType type;
  final DateTime date;
  final double amount;
  final ReamortizationMode reamortizationMode;
  final EarlyRepaymentExemption exemption;

  const LoanEvent({
    this.id = 0,
    required this.type,
    required this.date,
    this.amount = 0.0,
    this.reamortizationMode = ReamortizationMode.reduceDuration,
    this.exemption = EarlyRepaymentExemption.none,
  });

  bool get isTotalRepayment => type == LoanEventType.earlyRepaymentTotal;
}
