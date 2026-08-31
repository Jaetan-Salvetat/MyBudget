import 'package:mybudget/core/enums/frequency.dart';

class TransactionRuleVersion {
  final double amount;
  final DateTime startDate;
  final DateTime? endDate;
  final Frequency frequency;

  const TransactionRuleVersion({
    required this.amount,
    required this.startDate,
    required this.frequency,
    this.endDate,
  });

  bool get isOpen => endDate == null;
}
