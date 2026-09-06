import 'package:mybudget/core/enums/transaction_change.dart';

class TransactionChangeEntry {
  const TransactionChangeEntry({
    required this.at,
    required this.change,
    this.from,
    this.to,
  });
  final DateTime at;
  final TransactionChange change;
  final String? from;
  final String? to;
}
