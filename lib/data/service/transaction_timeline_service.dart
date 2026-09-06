import 'package:mybudget/core/enums/transaction_change.dart';
import 'package:mybudget/core/values/transaction_change_entry.dart';
import 'package:mybudget/core/values/transaction_rule_version.dart';

typedef AmountFormatter = String Function(double amount);

class TransactionTimelineService {
  const TransactionTimelineService._();

  static List<TransactionChangeEntry> build({
    required List<TransactionRuleVersion> versions,
    required List<TransactionChangeEntry> recorded,
    required AmountFormatter formatAmount,
  }) {
    if (versions.isEmpty) {
      throw ArgumentError.value(versions, 'versions', 'Aucune version fournie');
    }

    final ordered = [...versions]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final entries = <TransactionChangeEntry>[
      TransactionChangeEntry(
        at: ordered.first.startDate,
        change: TransactionChange.created,
      ),
    ];

    for (var index = 1; index < ordered.length; index++) {
      entries.addAll(
        _revisionOf(ordered[index - 1], ordered[index], formatAmount),
      );
    }

    final closing = ordered.last.endDate;
    if (closing != null) {
      entries.add(
        TransactionChangeEntry(at: closing, change: TransactionChange.closed),
      );
    }

    entries.addAll(recorded);

    return _newestFirst(entries);
  }

  static List<TransactionChangeEntry> _revisionOf(
    TransactionRuleVersion previous,
    TransactionRuleVersion next,
    AmountFormatter formatAmount,
  ) {
    final at = previous.endDate ?? next.startDate;
    final entries = <TransactionChangeEntry>[];

    void record(TransactionChange change, String? from, String? to) {
      if (from == to) return;
      entries.add(
        TransactionChangeEntry(at: at, change: change, from: from, to: to),
      );
    }

    record(TransactionChange.name, previous.name, next.name);
    record(
      TransactionChange.amount,
      formatAmount(previous.amount),
      formatAmount(next.amount),
    );
    record(
      TransactionChange.frequency,
      previous.frequency.label,
      next.frequency.label,
    );
    record(TransactionChange.account, previous.accountLabel, next.accountLabel);
    record(
      TransactionChange.beneficiary,
      previous.beneficiaryLabel,
      next.beneficiaryLabel,
    );

    return entries;
  }

  static List<TransactionChangeEntry> _newestFirst(
    List<TransactionChangeEntry> entries,
  ) {
    final indexed = entries.indexed.toList()
      ..sort((a, b) {
        final byDate = b.$2.at.compareTo(a.$2.at);
        return byDate != 0 ? byDate : a.$1.compareTo(b.$1);
      });
    return [for (final (_, entry) in indexed) entry];
  }
}
