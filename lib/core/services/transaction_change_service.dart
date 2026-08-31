import 'package:mybudget/core/entities/filterable_transaction.dart';
import 'package:mybudget/core/entities/transaction_change_entry.dart';
import 'package:mybudget/core/enums/transaction_change.dart';
import 'package:mybudget/utils/history_utils.dart';

class TransactionChangeService {
  const TransactionChangeService._();

  static bool changesTerms(
    FilterableTransaction before,
    FilterableTransaction after,
  ) {
    return before.name != after.name ||
        before.amount != after.amount ||
        before.accountId != after.accountId ||
        before.beneficiaryId != after.beneficiaryId ||
        before.frequencyEnum != after.frequencyEnum ||
        !sameSchedule(before.startDate, after.startDate, after.frequencyEnum);
  }

  static List<TransactionChangeEntry> inPlaceChanges(
    FilterableTransaction before,
    FilterableTransaction after, {
    required DateTime at,
    required bool forked,
  }) {
    final entries = <TransactionChangeEntry>[];

    void record(TransactionChange change, String? from, String? to) {
      if (from == to) return;
      entries.add(
        TransactionChangeEntry(at: at, change: change, from: from, to: to),
      );
    }

    record(
      TransactionChange.category,
      before.categorySlug,
      after.categorySlug,
    );

    if (forked) return entries;

    record(TransactionChange.name, before.name, after.name);
    record(
      TransactionChange.amount,
      before.amount.toString(),
      after.amount.toString(),
    );
    record(
      TransactionChange.frequency,
      before.frequencyEnum.label,
      after.frequencyEnum.label,
    );
    record(
      TransactionChange.account,
      before.accountId.toString(),
      after.accountId.toString(),
    );
    record(
      TransactionChange.beneficiary,
      before.beneficiaryId?.toString(),
      after.beneficiaryId?.toString(),
    );

    return entries;
  }
}
