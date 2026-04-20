import 'package:flutter_test/flutter_test.dart';
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
}
