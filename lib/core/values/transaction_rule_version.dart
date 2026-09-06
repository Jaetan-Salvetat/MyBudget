import 'package:mybudget/core/enums/frequency.dart';

class TransactionRuleVersion {
  const TransactionRuleVersion({
    required this.name,
    required this.amount,
    required this.startDate,
    required this.frequency,
    required this.accountLabel,
    this.beneficiaryLabel,
    this.endDate,
  });
  final String name;
  final double amount;
  final DateTime startDate;
  final DateTime? endDate;
  final Frequency frequency;
  final String accountLabel;
  final String? beneficiaryLabel;

  bool get isOpen => endDate == null;
}
