import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/entities/transaction_rule_version.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/services/transaction_rule_summary_service.dart';

void main() {
  TransactionRuleVersion version({
    double amount = 100,
    required DateTime startDate,
    DateTime? endDate,
    Frequency frequency = Frequency.monthly,
  }) {
    return TransactionRuleVersion(
      name: 'Loyer',
      amount: amount,
      startDate: startDate,
      endDate: endDate,
      frequency: frequency,
      accountLabel: 'Courant',
    );
  }

  group('occurrences', () {
    test('counts every landing up to a day already past this month', () {
      final summary = TransactionRuleSummaryService.summarize(
        [version(startDate: DateTime(2026, 3, 5))],
        asOf: DateTime(2026, 6, 20),
      );

      expect(summary.occurrences, 4);
      expect(summary.totalToDate, 400);
    });

    test('leaves out a landing still to come this month', () {
      final summary = TransactionRuleSummaryService.summarize(
        [version(startDate: DateTime(2026, 3, 25))],
        asOf: DateTime(2026, 6, 20),
      );

      expect(summary.occurrences, 3);
      expect(summary.nextDueDate, DateTime(2026, 6, 25));
    });

    test('counts the landing falling on the very day', () {
      final summary = TransactionRuleSummaryService.summarize(
        [version(startDate: DateTime(2026, 6, 20))],
        asOf: DateTime(2026, 6, 20),
      );

      expect(summary.occurrences, 1);
    });

    test('clamps a 31st to the last day of a shorter month', () {
      final summary = TransactionRuleSummaryService.summarize(
        [version(startDate: DateTime(2026, 1, 31))],
        asOf: DateTime(2026, 2, 28),
      );

      expect(summary.occurrences, 2);
    });

    test('counts an annual rule once a year', () {
      final summary = TransactionRuleSummaryService.summarize(
        [
          version(
            startDate: DateTime(2024, 4, 10),
            frequency: Frequency.annual,
          ),
        ],
        asOf: DateTime(2026, 6, 20),
      );

      expect(summary.occurrences, 3);
    });

    test('counts a one-time rule once it has landed', () {
      final summary = TransactionRuleSummaryService.summarize(
        [
          version(
            startDate: DateTime(2026, 6, 2),
            frequency: Frequency.oneTime,
          ),
        ],
        asOf: DateTime(2026, 6, 20),
      );

      expect(summary.occurrences, 1);
    });

    test('counts nothing for a rule that has not started', () {
      final summary = TransactionRuleSummaryService.summarize(
        [version(startDate: DateTime(2026, 8, 5))],
        asOf: DateTime(2026, 6, 20),
      );

      expect(summary.occurrences, 0);
      expect(summary.totalToDate, 0);
    });

    test('stops counting at the closing date', () {
      final summary = TransactionRuleSummaryService.summarize(
        [
          version(
            startDate: DateTime(2026, 1, 10),
            endDate: DateTime(2026, 3, 15),
          ),
        ],
        asOf: DateTime(2026, 6, 20),
      );

      expect(summary.occurrences, 3);
    });
  });

  group('next due date', () {
    test('is the next monthly landing', () {
      final summary = TransactionRuleSummaryService.summarize(
        [version(startDate: DateTime(2026, 3, 5))],
        asOf: DateTime(2026, 6, 20),
      );

      expect(summary.nextDueDate, DateTime(2026, 7, 5));
    });

    test('is the next anniversary of an annual rule', () {
      final summary = TransactionRuleSummaryService.summarize(
        [
          version(
            startDate: DateTime(2024, 4, 10),
            frequency: Frequency.annual,
          ),
        ],
        asOf: DateTime(2026, 6, 20),
      );

      expect(summary.nextDueDate, DateTime(2027, 4, 10));
    });

    test('is the date itself for a one-time rule still ahead', () {
      final summary = TransactionRuleSummaryService.summarize(
        [
          version(
            startDate: DateTime(2028, 9, 3),
            frequency: Frequency.oneTime,
          ),
        ],
        asOf: DateTime(2026, 6, 20),
      );

      expect(summary.nextDueDate, DateTime(2028, 9, 3));
    });

    test('is nothing for a one-time rule already landed', () {
      final summary = TransactionRuleSummaryService.summarize(
        [
          version(
            startDate: DateTime(2026, 6, 2),
            frequency: Frequency.oneTime,
          ),
        ],
        asOf: DateTime(2026, 6, 20),
      );

      expect(summary.nextDueDate, isNull);
    });

    test('is nothing for a closed rule', () {
      final summary = TransactionRuleSummaryService.summarize(
        [
          version(
            startDate: DateTime(2026, 1, 10),
            endDate: DateTime(2026, 3, 15),
          ),
        ],
        asOf: DateTime(2026, 6, 20),
      );

      expect(summary.nextDueDate, isNull);
    });
  });

  group('annual impact', () {
    test('spreads a monthly amount over twelve months', () {
      final summary = TransactionRuleSummaryService.summarize(
        [version(amount: 30, startDate: DateTime(2026, 3, 5))],
        asOf: DateTime(2026, 6, 20),
      );

      expect(summary.annualImpact, 360);
    });

    test('takes an annual amount as it is', () {
      final summary = TransactionRuleSummaryService.summarize(
        [
          version(
            amount: 240,
            startDate: DateTime(2026, 3, 5),
            frequency: Frequency.annual,
          ),
        ],
        asOf: DateTime(2026, 6, 20),
      );

      expect(summary.annualImpact, 240);
    });

    test('has none for a one-time rule', () {
      final summary = TransactionRuleSummaryService.summarize(
        [
          version(
            startDate: DateTime(2026, 6, 2),
            frequency: Frequency.oneTime,
          ),
        ],
        asOf: DateTime(2026, 6, 20),
      );

      expect(summary.annualImpact, isNull);
    });
  });

  group('a chain of versions', () {
    final revised = [
      version(
        amount: 800,
        startDate: DateTime(2026, 1, 10),
        endDate: DateTime(2026, 3, 20),
      ),
      version(amount: 900, startDate: DateTime(2026, 4, 10)),
    ];

    test('adds up what each version has cost', () {
      final summary = TransactionRuleSummaryService.summarize(
        revised,
        asOf: DateTime(2026, 6, 20),
      );

      expect(summary.occurrences, 6);
      expect(summary.totalToDate, 5100);
    });

    test('starts at the oldest version', () {
      final summary = TransactionRuleSummaryService.summarize(
        revised,
        asOf: DateTime(2026, 6, 20),
      );

      expect(summary.since, DateTime(2026, 1, 10));
    });

    test('reads its schedule off the open version', () {
      final summary = TransactionRuleSummaryService.summarize(
        revised,
        asOf: DateTime(2026, 6, 20),
      );

      expect(summary.nextDueDate, DateTime(2026, 7, 10));
      expect(summary.annualImpact, 10800);
    });

    test('falls back to the latest version once all are closed', () {
      final summary = TransactionRuleSummaryService.summarize(
        [
          version(
            amount: 800,
            startDate: DateTime(2026, 1, 10),
            endDate: DateTime(2026, 3, 20),
          ),
          version(
            amount: 900,
            startDate: DateTime(2026, 4, 10),
            endDate: DateTime(2026, 5, 20),
          ),
        ],
        asOf: DateTime(2026, 6, 20),
      );

      expect(summary.nextDueDate, isNull);
      expect(summary.annualImpact, 10800);
    });
  });

  test('refuses a rule without any version', () {
    expect(
      () => TransactionRuleSummaryService.summarize(
        const [],
        asOf: DateTime(2026, 6, 20),
      ),
      throwsArgumentError,
    );
  });
}
