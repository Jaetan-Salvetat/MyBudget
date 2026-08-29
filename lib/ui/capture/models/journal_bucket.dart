import 'package:intl/intl.dart';
import 'package:mybudget/ui/capture/models/journal_entry.dart';

/// How the journal cuts the past up. The resolution decays with distance :
/// a day while it is still remembered, then a week, then a month.
///
/// Declaration order is reading order.
enum JournalBucketKind {
  today('Aujourd\'hui'),
  yesterday('Hier'),
  thisWeek('Cette semaine'),
  lastWeek('La semaine dernière'),
  earlierThisMonth('Plus tôt ce mois-ci'),

  /// A whole calendar month, labelled by its own name.
  month('');

  const JournalBucketKind(this.label);

  final String label;
}

/// One slice of the past with everything it recorded, newest line first.
class JournalBucket {
  final JournalBucketKind kind;

  /// A day inside the slice. Only the month buckets read it, to name
  /// themselves.
  final DateTime anchor;

  final List<JournalEntry> entries;

  const JournalBucket({
    required this.kind,
    required this.anchor,
    required this.entries,
  });

  String get label => kind == JournalBucketKind.month
      ? DateFormat('MMMM yyyy', 'fr_FR').format(anchor)
      : kind.label;

  /// What the slice cost, revenues taken off : the direction the journal
  /// reads in.
  double get spent => entries.fold(
    0.0,
    (sum, entry) => entry.isIncome ? sum - entry.amount : sum + entry.amount,
  );

  /// Close enough to now that the hour still means something ; further back
  /// a line says which day it was instead.
  bool get keepsTheHour =>
      kind == JournalBucketKind.today || kind == JournalBucketKind.yesterday;

  /// A past month can be folded away once it has been read ; it opens open,
  /// like everything else.
  bool get isCollapsible => kind == JournalBucketKind.month;
}
