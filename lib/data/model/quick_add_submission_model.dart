import 'package:mybudget/core/enums/transaction_type.dart';

class QuickAddSubmission {
  const QuickAddSubmission({
    required this.id,
    required this.type,
    required this.name,
    required this.amount,
  });
  final int id;
  final TransactionType type;
  final String name;
  final double amount;
}
