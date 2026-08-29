import 'package:mybudget/core/enums/transaction_type.dart';

/// Where a line comes from. Ids are only unique within a table, so nothing
/// but the source tells an expense #7 from a loan #7.
enum JournalEntrySource { expense, revenue, loan }

/// A transaction dated on the journal's day, ready to be drawn as one line.
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

  /// A transaction typed through the quick-add carries the moment it landed ;
  /// one filled in a form only carries a day, and has no hour to show.
  bool get hasTime => at.hour != 0 || at.minute != 0;

  bool get isIncome => type == TransactionType.income;

  /// Whether this line is the transaction the quick-add just recorded. A loan
  /// instalment never is : it answers to no submission.
  bool sameTransaction(TransactionType type, int id) =>
      this.id == id &&
      source ==
          (type == TransactionType.income
              ? JournalEntrySource.revenue
              : JournalEntrySource.expense);
}
