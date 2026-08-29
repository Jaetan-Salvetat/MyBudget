import 'package:mybudget/core/enums/transaction_type.dart';

/// A transaction just created by the quick-add, kept only long enough to be
/// undone from the journal line it became.
class QuickAddSubmission {
  final int id;
  final TransactionType type;
  final String name;
  final double amount;

  /// The category it was recorded under : it is what colours the wash the
  /// screen takes as the line lands.
  final String categorySlug;

  const QuickAddSubmission({
    required this.id,
    required this.type,
    required this.name,
    required this.amount,
    required this.categorySlug,
  });
}
