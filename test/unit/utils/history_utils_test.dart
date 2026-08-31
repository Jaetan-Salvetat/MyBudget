import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/recurring_deletion.dart';
import 'package:mybudget/utils/history_utils.dart';

void main() {
  group('isActiveForMonth', () {
    test('active when no endDate and startDate before month', () {
      final startDate = DateTime(2024, 1, 15);
      final month = DateTime(2024, 6, 1);

      expect(isActiveForMonth(startDate, null, month), isTrue);
    });

    test('active when startDate is within the month', () {
      final startDate = DateTime(2024, 6, 15);
      final month = DateTime(2024, 6, 1);

      expect(isActiveForMonth(startDate, null, month), isTrue);
    });

    test('inactive when startDate is after the month', () {
      final startDate = DateTime(2024, 7, 1);
      final month = DateTime(2024, 6, 1);

      expect(isActiveForMonth(startDate, null, month), isFalse);
    });

    test('inactive when endDate is before the month', () {
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 5, 15);
      final month = DateTime(2024, 6, 1);

      expect(isActiveForMonth(startDate, endDate, month), isFalse);
    });

    test('active when endDate is within the month', () {
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 6, 15);
      final month = DateTime(2024, 6, 1);

      expect(isActiveForMonth(startDate, endDate, month), isTrue);
    });

    test('edge case: startDate on first day of month', () {
      final startDate = DateTime(2024, 6, 1);
      final month = DateTime(2024, 6, 1);

      expect(isActiveForMonth(startDate, null, month), isTrue);
    });

    test('edge case: endDate on last day of month', () {
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 6, 30);
      final month = DateTime(2024, 6, 1);

      expect(isActiveForMonth(startDate, endDate, month), isTrue);
    });
  });

  group('occursInMonth', () {
    test('a monthly rule falls on every month it is alive', () {
      final startDate = DateTime(2026, 4, 12);

      expect(
        occursInMonth(startDate, null, Frequency.monthly, DateTime(2026, 4)),
        isTrue,
      );
      expect(
        occursInMonth(startDate, null, Frequency.monthly, DateTime(2026, 8)),
        isTrue,
      );
    });

    test('a monthly rule falls on no month before it started', () {
      expect(
        occursInMonth(
          DateTime(2026, 4, 12),
          null,
          Frequency.monthly,
          DateTime(2026, 3),
        ),
        isFalse,
      );
    });

    test('a rule closed in August still falls on August', () {
      expect(
        occursInMonth(
          DateTime(2026, 4, 12),
          DateTime(2026, 8, 12),
          Frequency.monthly,
          DateTime(2026, 8),
        ),
        isTrue,
      );
    });

    test('a rule closed in August falls on nothing after it', () {
      expect(
        occursInMonth(
          DateTime(2026, 4, 12),
          DateTime(2026, 8, 12),
          Frequency.monthly,
          DateTime(2026, 9),
        ),
        isFalse,
      );
    });

    test('a yearly rule falls only on its own month', () {
      final startDate = DateTime(2026, 3, 8);

      expect(
        occursInMonth(startDate, null, Frequency.annual, DateTime(2027, 3)),
        isTrue,
      );
      expect(
        occursInMonth(startDate, null, Frequency.annual, DateTime(2027, 4)),
        isFalse,
      );
    });

    test('a yearly rule falls on no March before its first', () {
      expect(
        occursInMonth(
          DateTime(2026, 3, 8),
          null,
          Frequency.annual,
          DateTime(2025, 3),
        ),
        isFalse,
      );
    });

    test('a one-off falls on its month alone', () {
      final startDate = DateTime(2026, 5, 20);

      expect(
        occursInMonth(startDate, null, Frequency.oneTime, DateTime(2026, 5)),
        isTrue,
      );
      expect(
        occursInMonth(startDate, null, Frequency.oneTime, DateTime(2027, 5)),
        isFalse,
      );
    });
  });

  group('occursInMonth, at day resolution', () {
    test('a rule closed on the 29th keeps the 8th it paid that month', () {
      expect(
        occursInMonth(
          DateTime(2026, 4, 8),
          DateTime(2026, 8, 29),
          Frequency.monthly,
          DateTime(2026, 8),
        ),
        isTrue,
      );
    });

    test('a rule closed on the 29th drops the 30th it never paid', () {
      expect(
        occursInMonth(
          DateTime(2026, 4, 30),
          DateTime(2026, 8, 29),
          Frequency.monthly,
          DateTime(2026, 8),
        ),
        isFalse,
      );
    });

    test('a rule started on the 20th keeps the month it started in', () {
      expect(
        occursInMonth(
          DateTime(2026, 8, 20),
          null,
          Frequency.monthly,
          DateTime(2026, 8),
        ),
        isTrue,
      );
    });

    test('a rule opened and closed the same day keeps that day', () {
      expect(
        occursInMonth(
          DateTime(2026, 8, 8),
          DateTime(2026, 8, 8),
          Frequency.monthly,
          DateTime(2026, 8),
        ),
        isTrue,
      );
    });

    test('an end that precedes the start falls on no month at all', () {
      expect(
        occursInMonth(
          DateTime(2026, 9, 8),
          DateTime(2026, 8, 8),
          Frequency.monthly,
          DateTime(2026, 8),
        ),
        isFalse,
      );
      expect(
        occursInMonth(
          DateTime(2026, 9, 8),
          DateTime(2026, 8, 8),
          Frequency.monthly,
          DateTime(2026, 9),
        ),
        isFalse,
      );
    });
  });

  group('hasOccurredThisMonth', () {
    test('the 12th has fallen when we are the 29th', () {
      expect(
        hasOccurredThisMonth(
          DateTime(2026, 4, 12),
          null,
          Frequency.monthly,
          DateTime(2026, 8, 29),
        ),
        isTrue,
      );
    });

    test('the 30th has not fallen when we are the 29th', () {
      expect(
        hasOccurredThisMonth(
          DateTime(2026, 4, 30),
          null,
          Frequency.monthly,
          DateTime(2026, 8, 29),
        ),
        isFalse,
      );
    });

    test('the day itself counts as fallen', () {
      expect(
        hasOccurredThisMonth(
          DateTime(2026, 4, 29),
          null,
          Frequency.monthly,
          DateTime(2026, 8, 29),
        ),
        isTrue,
      );
    });

    test('a yearly rule outside its month has nothing falling', () {
      expect(
        hasOccurredThisMonth(
          DateTime(2026, 3, 12),
          null,
          Frequency.annual,
          DateTime(2026, 8, 29),
        ),
        isFalse,
      );
    });
  });

  group('closingDateOf', () {
    final startDate = DateTime(2026, 4, 12);
    final asOf = DateTime(2026, 8, 29);

    test('leaving this month its due closes on the day of the deletion', () {
      expect(
        closingDateOf(
          RecurringDeletion.afterThisMonth,
          startDate,
          Frequency.monthly,
          asOf,
        ),
        DateTime(2026, 8, 29),
      );
    });

    test('taking this month too closes the eve of its due date', () {
      expect(
        closingDateOf(
          RecurringDeletion.includingThisMonth,
          startDate,
          Frequency.monthly,
          asOf,
        ),
        DateTime(2026, 8, 11),
      );
    });

    test('taking this month too leaves the months before it alone', () {
      final closing = closingDateOf(
        RecurringDeletion.includingThisMonth,
        startDate,
        Frequency.monthly,
        asOf,
      );

      expect(
        occursInMonth(startDate, closing, Frequency.monthly, DateTime(2026, 8)),
        isFalse,
      );
      expect(
        occursInMonth(startDate, closing, Frequency.monthly, DateTime(2026, 7)),
        isTrue,
      );
    });

    test('a yearly rule loses this year and keeps the one before', () {
      final anniversary = DateTime(2025, 3, 12);
      final closing = closingDateOf(
        RecurringDeletion.includingThisMonth,
        anniversary,
        Frequency.annual,
        DateTime(2026, 3, 29),
      );

      expect(
        occursInMonth(anniversary, closing, Frequency.annual, DateTime(2026, 3)),
        isFalse,
      );
      expect(
        occursInMonth(anniversary, closing, Frequency.annual, DateTime(2025, 3)),
        isTrue,
      );
    });
  });

  group('dayInMonthOf', () {
    test('keeps the day of the month a recurring rule started on', () {
      expect(
        dayInMonthOf(DateTime(2026, 4, 12), Frequency.monthly, DateTime(2026, 8)),
        DateTime(2026, 8, 12),
      );
    });

    test('brings the 31st back to the last day of a shorter month', () {
      expect(
        dayInMonthOf(DateTime(2026, 1, 31), Frequency.monthly, DateTime(2026, 2)),
        DateTime(2026, 2, 28),
      );
    });

    test('a yearly rule keeps its own month, whatever the year', () {
      expect(
        dayInMonthOf(DateTime(2026, 3, 8), Frequency.annual, DateTime(2028, 3)),
        DateTime(2028, 3, 8),
      );
    });

    test('a one-off keeps the date it was recorded on', () {
      expect(
        dayInMonthOf(
          DateTime(2026, 5, 20, 14, 30),
          Frequency.oneTime,
          DateTime(2026, 5),
        ),
        DateTime(2026, 5, 20, 14, 30),
      );
    });
  });

  group('computeNewStartDate', () {
    test('already paid returns next month paymentDay', () {
      final now = DateTime(2024, 6, 20);
      const paymentDay = 15;

      final result = computeNewStartDate(now, paymentDay);

      expect(result, DateTime(2024, 7, 15));
    });

    test('not yet paid returns this month paymentDay', () {
      final now = DateTime(2024, 6, 10);
      const paymentDay = 15;

      final result = computeNewStartDate(now, paymentDay);

      expect(result, DateTime(2024, 6, 15));
    });

    test('December edge case: next month is January of next year', () {
      final now = DateTime(2024, 12, 20);
      const paymentDay = 15;

      final result = computeNewStartDate(now, paymentDay);

      expect(result, DateTime(2025, 1, 15));
    });

    test('day 31 clamping in next month with fewer days', () {
      final now = DateTime(2024, 1, 31);
      const paymentDay = 30;

      final result = computeNewStartDate(now, paymentDay);

      expect(result, DateTime(2024, 2, 29));
    });
  });

  group('occursOnDay', () {
    test('a one-time transaction only lands on its own day', () {
      final start = DateTime(2026, 8, 14, 18, 42);

      expect(
        occursOnDay(start, null, Frequency.oneTime, DateTime(2026, 8, 14)),
        isTrue,
      );
      expect(
        occursOnDay(start, null, Frequency.oneTime, DateTime(2026, 8, 15)),
        isFalse,
      );
      expect(
        occursOnDay(start, null, Frequency.oneTime, DateTime(2026, 9, 14)),
        isFalse,
      );
    });

    test('a monthly transaction lands every month on its start day', () {
      final start = DateTime(2026, 3, 5);

      expect(
        occursOnDay(start, null, Frequency.monthly, DateTime(2026, 8, 5)),
        isTrue,
      );
      expect(
        occursOnDay(start, null, Frequency.monthly, DateTime(2026, 8, 6)),
        isFalse,
      );
    });

    test('a monthly transaction clamps to the last day of a shorter month', () {
      final start = DateTime(2026, 1, 31);

      expect(
        occursOnDay(start, null, Frequency.monthly, DateTime(2026, 2, 28)),
        isTrue,
      );
      expect(
        occursOnDay(start, null, Frequency.monthly, DateTime(2026, 2, 27)),
        isFalse,
      );
    });

    test('an annual transaction lands once a year', () {
      final start = DateTime(2024, 6, 12);

      expect(
        occursOnDay(start, null, Frequency.annual, DateTime(2026, 6, 12)),
        isTrue,
      );
      expect(
        occursOnDay(start, null, Frequency.annual, DateTime(2026, 7, 12)),
        isFalse,
      );
    });

    test('nothing lands before it started or after it ended', () {
      final start = DateTime(2026, 3, 5);

      expect(
        occursOnDay(start, null, Frequency.monthly, DateTime(2026, 2, 5)),
        isFalse,
      );
      expect(
        occursOnDay(
          start,
          DateTime(2026, 6, 30),
          Frequency.monthly,
          DateTime(2026, 8, 5),
        ),
        isFalse,
      );
    });
  });

  group('initialDeletionScopeOf', () {
    test('leaves a one-time rule without any scope', () {
      expect(
        initialDeletionScopeOf(
          DateTime(2026, 6, 5),
          null,
          Frequency.oneTime,
          DateTime(2026, 6, 20),
        ),
        isNull,
      );
    });

    test('spares the month already charged', () {
      expect(
        initialDeletionScopeOf(
          DateTime(2026, 3, 5),
          null,
          Frequency.monthly,
          DateTime(2026, 6, 20),
        ),
        RecurringDeletion.afterThisMonth,
      );
    });

    test('drops the month still to be charged', () {
      expect(
        initialDeletionScopeOf(
          DateTime(2026, 3, 25),
          null,
          Frequency.monthly,
          DateTime(2026, 6, 20),
        ),
        RecurringDeletion.includingThisMonth,
      );
    });
  });
}
