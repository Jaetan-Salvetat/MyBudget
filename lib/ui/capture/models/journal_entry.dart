import 'package:mybudget/core/enums/transaction_type.dart';

/// A transaction dated on the journal's day, ready to be drawn as one line.
class JournalEntry {
  final int id;
  final TransactionType type;
  final String name;
  final double amount;
  final DateTime at;
  final String? categorySlug;

  const JournalEntry({
    required this.id,
    required this.type,
    required this.name,
    required this.amount,
    required this.at,
    required this.categorySlug,
  });

  /// A transaction typed through the quick-add carries the moment it landed ;
  /// one filled in a form only carries a day, and has no hour to show.
  bool get hasTime => at.hour != 0 || at.minute != 0;

  bool get isIncome => type == TransactionType.income;

  /// An expense and a revenue can share an id : they live in different tables.
  bool sameTransaction(TransactionType type, int id) =>
      this.type == type && this.id == id;
}
