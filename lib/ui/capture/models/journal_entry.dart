import 'package:mybudget/core/enums/transaction_type.dart';

enum JournalEntrySource { expense, revenue, loan }

class JournalEntry {
  final int id;
  final JournalEntrySource source;
  final TransactionType type;
  final String name;
  final double amount;
  final DateTime at;
  final String? categorySlug;

  const JournalEntry({
    required this.id,
    required this.source,
    required this.type,
    required this.name,
    required this.amount,
    required this.at,
    required this.categorySlug,
  });

  bool get hasTime => at.hour != 0 || at.minute != 0;

  bool get isIncome => type == TransactionType.income;

  bool sameTransaction(TransactionType type, int id) =>
      this.id == id &&
      source ==
          (type == TransactionType.income
              ? JournalEntrySource.revenue
              : JournalEntrySource.expense);
}
