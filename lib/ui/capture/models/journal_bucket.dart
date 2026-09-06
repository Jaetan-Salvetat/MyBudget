import 'package:mybudget/core/formatting/date_formatter.dart';
import 'package:mybudget/ui/capture/models/journal_entry.dart';

enum JournalBucketKind {
  today('Aujourd\'hui'),
  yesterday('Hier'),
  thisWeek('Cette semaine'),
  lastWeek('La semaine dernière'),
  earlierThisMonth('Plus tôt ce mois-ci'),

  month('');

  const JournalBucketKind(this.label);

  final String label;
}

class JournalBucket {
  final JournalBucketKind kind;

  final DateTime anchor;

  final List<JournalEntry> entries;

  const JournalBucket({
    required this.kind,
    required this.anchor,
    required this.entries,
  });

  String get label => kind == JournalBucketKind.month
      ? DateFormatter.monthYear.format(anchor)
      : kind.label;

  double get spent => entries.fold(
    0.0,
    (sum, entry) => entry.isIncome ? sum - entry.amount : sum + entry.amount,
  );

  bool get keepsTheHour =>
      kind == JournalBucketKind.today || kind == JournalBucketKind.yesterday;

  bool get isCollapsible => kind == JournalBucketKind.month;
}
