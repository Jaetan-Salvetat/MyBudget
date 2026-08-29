import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/frequency.dart';
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

  group('computeEndDate', () {
    test('already paid this month returns this month paymentDay', () {
      final now = DateTime(2024, 6, 20);
      const paymentDay = 15;

      final result = computeEndDate(now, paymentDay);

      expect(result, DateTime(2024, 6, 15));
    });

    test('not yet paid returns previous month paymentDay', () {
      final now = DateTime(2024, 6, 10);
      const paymentDay = 15;

      final result = computeEndDate(now, paymentDay);

      expect(result, DateTime(2024, 5, 15));
    });

    test('day 31 in month with 30 days is clamped to 30', () {
      final now = DateTime(2024, 7, 5);
      const paymentDay = 31;

      final result = computeEndDate(now, paymentDay);

      expect(result, DateTime(2024, 6, 30));
    });

    test('January edge case: previous month is December of previous year', () {
      final now = DateTime(2024, 1, 10);
      const paymentDay = 15;

      final result = computeEndDate(now, paymentDay);

      expect(result, DateTime(2023, 12, 15));
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
}
