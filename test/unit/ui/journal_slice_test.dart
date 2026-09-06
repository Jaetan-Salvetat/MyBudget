import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/ui/capture/capture_provider.dart';
import 'package:mybudget/ui/capture/models/journal_bucket.dart';

void main() {
  group('journalSliceOf, from a Thursday in the middle of the month', () {
    final today = DateTime(2026, 8, 20);

    test('the two days that still have a name keep one', () {
      expect(journalSliceOf(today, today), JournalBucketKind.today);
      expect(
        journalSliceOf(DateTime(2026, 8, 19), today),
        JournalBucketKind.yesterday,
      );
    });

    test('the week runs from its Monday', () {
      expect(
        journalSliceOf(DateTime(2026, 8, 18), today),
        JournalBucketKind.thisWeek,
      );
      expect(
        journalSliceOf(DateTime(2026, 8, 17), today),
        JournalBucketKind.thisWeek,
      );
      expect(
        journalSliceOf(DateTime(2026, 8, 16), today),
        JournalBucketKind.lastWeek,
      );
      expect(
        journalSliceOf(DateTime(2026, 8, 10), today),
        JournalBucketKind.lastWeek,
      );
    });

    test('what the two weeks leave is the rest of the month', () {
      expect(
        journalSliceOf(DateTime(2026, 8, 9), today),
        JournalBucketKind.earlierThisMonth,
      );
      expect(
        journalSliceOf(DateTime(2026, 8, 1), today),
        JournalBucketKind.earlierThisMonth,
      );
    });

    test('anything older is a month of its own', () {
      expect(
        journalSliceOf(DateTime(2026, 7, 31), today),
        JournalBucketKind.month,
      );
      expect(
        journalSliceOf(DateTime(2026, 6, 15), today),
        JournalBucketKind.month,
      );
    });
  });

  group('journalSliceOf, early in the month', () {
    final today = DateTime(2026, 8, 5);

    test('a week never steals days from the month before it', () {
      expect(
        journalSliceOf(DateTime(2026, 7, 30), today),
        JournalBucketKind.month,
      );
      expect(
        journalSliceOf(DateTime(2026, 8, 3), today),
        JournalBucketKind.thisWeek,
      );
    });

    test('the first of the month falls in last week, and stays in it', () {
      expect(
        journalSliceOf(DateTime(2026, 8, 1), today),
        JournalBucketKind.lastWeek,
      );
    });
  });

  group('startOfWeek', () {
    test('a Monday is its own start', () {
      expect(startOfWeek(DateTime(2026, 8, 17, 22)), DateTime(2026, 8, 17));
    });

    test('a Sunday reaches back six days', () {
      expect(startOfWeek(DateTime(2026, 8, 23)), DateTime(2026, 8, 17));
    });
  });
}
