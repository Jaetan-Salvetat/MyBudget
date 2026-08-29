import 'package:mybudget/ui/capture/models/journal_entry.dart';

/// One day of the month with everything it recorded, newest line first.
class JournalDay {
  final DateTime day;
  final List<JournalEntry> entries;

  const JournalDay({required this.day, required this.entries});

  /// What the day cost, revenues taken off : the direction the journal reads
  /// in.
  double get spent => entries.fold(
    0.0,
    (sum, entry) => entry.isIncome ? sum - entry.amount : sum + entry.amount,
  );

  bool isSameDay(DateTime other) =>
      day.year == other.year && day.month == other.month && day.day == other.day;
}
