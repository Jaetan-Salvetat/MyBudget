import 'package:mybudget/core/contracts/filterable_transaction.dart';
import 'package:mybudget/data/model/transaction_filter_data.dart';

class TransactionFilterService {
  const TransactionFilterService._();

  static bool matches(
    FilterableTransaction transaction,
    TransactionFilterData filter, {
    required String? groupKey,
  }) {
    final query = filter.searchQuery;
    if (query != null && query.isNotEmpty) {
      if (!transaction.name.toLowerCase().contains(query.toLowerCase())) {
        return false;
      }
    }
    if (filter.minAmount != null && transaction.amount < filter.minAmount!) {
      return false;
    }
    if (filter.maxAmount != null && transaction.amount > filter.maxAmount!) {
      return false;
    }
    if (filter.groupKeys.isNotEmpty && !filter.groupKeys.contains(groupKey)) {
      return false;
    }
    if (filter.accountIds.isNotEmpty &&
        !filter.accountIds.contains(transaction.accountId)) {
      return false;
    }
    if (filter.beneficiaryIds.isNotEmpty &&
        !filter.beneficiaryIds.contains(transaction.beneficiaryId)) {
      return false;
    }
    if (filter.types.isNotEmpty &&
        !filter.types.contains(transaction.frequencyEnum)) {
      return false;
    }
    return true;
  }

  static List<T> apply<T extends FilterableTransaction>(
    List<T> transactions,
    TransactionFilterData filter, {
    required String? Function(T transaction) groupKeyOf,
  }) {
    return transactions
        .where(
          (transaction) =>
              matches(transaction, filter, groupKey: groupKeyOf(transaction)),
        )
        .toList();
  }
}
