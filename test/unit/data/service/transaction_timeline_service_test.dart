import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_change.dart';
import 'package:mybudget/core/values/transaction_change_entry.dart';
import 'package:mybudget/core/values/transaction_rule_version.dart';
import 'package:mybudget/data/service/transaction_timeline_service.dart';

void main() {
  String euros(double amount) => '$amount €';

  TransactionRuleVersion version({
    String name = 'Loyer',
    double amount = 800,
    required DateTime startDate,
    DateTime? endDate,
    Frequency frequency = Frequency.monthly,
    String accountLabel = 'Courant',
    String? beneficiaryLabel,
  }) {
    return TransactionRuleVersion(
      name: name,
      amount: amount,
      startDate: startDate,
      endDate: endDate,
      frequency: frequency,
      accountLabel: accountLabel,
      beneficiaryLabel: beneficiaryLabel,
    );
  }

  List<TransactionChangeEntry> timelineOf(
    List<TransactionRuleVersion> versions, {
    List<TransactionChangeEntry> recorded = const [],
  }) {
    return TransactionTimelineService.build(
      versions: versions,
      recorded: recorded,
      formatAmount: euros,
    );
  }

  test('an untouched rule only tells when it was created', () {
    final timeline = timelineOf([version(startDate: DateTime(2026, 1, 10))]);

    expect(timeline.single.change, TransactionChange.created);
    expect(timeline.single.at, DateTime(2026, 1, 10));
  });

  test('a revision tells the price it left and the one it took', () {
    final timeline = timelineOf([
      version(startDate: DateTime(2026, 1, 10), endDate: DateTime(2026, 3, 20)),
      version(amount: 900, startDate: DateTime(2026, 4, 10)),
    ]);

    final amountChange = timeline.firstWhere(
      (entry) => entry.change == TransactionChange.amount,
    );
    expect(amountChange.from, euros(800));
    expect(amountChange.to, euros(900));
  });

  test('a revision is dated on the day it was decided', () {
    final timeline = timelineOf([
      version(startDate: DateTime(2026, 1, 10), endDate: DateTime(2026, 3, 20)),
      version(amount: 900, startDate: DateTime(2026, 4, 10)),
    ]);

    expect(
      timeline
          .firstWhere((entry) => entry.change == TransactionChange.amount)
          .at,
      DateTime(2026, 3, 20),
    );
  });

  test('a renaming, a new rhythm, a new account and a new payee all show', () {
    final timeline = timelineOf([
      version(startDate: DateTime(2026, 1, 10), endDate: DateTime(2026, 3, 20)),
      version(
        name: 'Loyer appart',
        startDate: DateTime(2026, 4, 10),
        frequency: Frequency.annual,
        accountLabel: 'Livret',
        beneficiaryLabel: 'Marie',
      ),
    ]);

    expect(
      timeline.map((entry) => entry.change),
      containsAll(<TransactionChange>[
        TransactionChange.name,
        TransactionChange.frequency,
        TransactionChange.account,
        TransactionChange.beneficiary,
      ]),
    );
  });

  test('a closed rule tells when it ended', () {
    final timeline = timelineOf([
      version(startDate: DateTime(2026, 1, 10), endDate: DateTime(2026, 3, 20)),
    ]);

    expect(timeline.first.change, TransactionChange.closed);
    expect(timeline.first.at, DateTime(2026, 3, 20));
  });

  test('a recorded change joins the story', () {
    final timeline = timelineOf(
      [version(startDate: DateTime(2026, 1, 10))],
      recorded: [
        TransactionChangeEntry(
          at: DateTime(2026, 2, 5),
          change: TransactionChange.category,
          from: 'Loyer',
          to: 'Charges',
        ),
      ],
    );

    expect(timeline.first.change, TransactionChange.category);
    expect(timeline.last.change, TransactionChange.created);
  });

  test('the latest change comes first', () {
    final timeline = timelineOf(
      [
        version(
          startDate: DateTime(2026, 1, 10),
          endDate: DateTime(2026, 3, 20),
        ),
        version(amount: 900, startDate: DateTime(2026, 4, 10)),
      ],
      recorded: [
        TransactionChangeEntry(
          at: DateTime(2026, 2, 5),
          change: TransactionChange.category,
        ),
      ],
    );

    expect(timeline.map((entry) => entry.change).toList(), [
      TransactionChange.amount,
      TransactionChange.category,
      TransactionChange.created,
    ]);
  });

  test('refuses a rule without any version', () {
    expect(() => timelineOf(const []), throwsArgumentError);
  });
}
