import 'package:mybudget/core/entities/loan.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/capture/models/journal_bucket.dart';
import 'package:mybudget/ui/capture/models/journal_entry.dart';
import 'package:mybudget/ui/expenses/expense_queries.dart';
import 'package:mybudget/ui/loans/loan_queries.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/ui/revenues/revenue_queries.dart';
import 'package:mybudget/utils/history_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'capture_provider.g.dart';

/// A loan instalment is a credit repayment, and the taxonomy already has a
/// name and a colour for that. Nothing about a loan says otherwise.
const String kLoanCategorySlug = 'finance.credit_pret';

/// What the month has left once everything it already owes is counted. The
/// capture screen shows that figure and nothing else : it is the consequence
/// of what was just typed, not a summary of the month.
@Riverpod(keepAlive: true)
double remainingThisMonth(Ref ref) {
  return ref.watch(currentMonthRevenuesProvider) -
      ref.watch(currentMonthExpensesProvider) -
      ref.watch(totalMonthlyLoanPaymentsProvider);
}

/// The past cut into slices that get coarser as they get older, newest first
/// throughout. Empty slices are dropped rather than drawn hollow.
@Riverpod(keepAlive: true)
List<JournalBucket> journalBuckets(Ref ref) {
  final expenses = ref.watch(expenseHistoryProvider);
  final revenues = ref.watch(revenueHistoryProvider);
  final loans = ref.watch(loanProvider).value ?? const <Loan>[];
  final today = dayOnly(DateTime.now());

  final byBucket = <_BucketKey, List<JournalEntry>>{};

  void place(
    DateTime month,
    DateTime startDate,
    DateTime? endDate,
    Frequency frequency,
    JournalEntry Function(DateTime at) build,
  ) {
    final day = _dayInMonth(startDate, frequency, month);
    if (day == null || day.isAfter(today)) return;
    if (!occursOnDay(startDate, endDate, frequency, day)) return;

    byBucket
        .putIfAbsent(_bucketKeyOf(day, today), () => <JournalEntry>[])
        .add(build(_occurrence(startDate, frequency, day)));
  }

  // Back to the oldest transaction on record : a monthly expense created in
  // June shows up in June, July and August, and a yearly one created last
  // August shows up in both Augusts.
  final oldest = _oldestStart(expenses, revenues);
  final firstMonth = oldest == null
      ? DateTime(today.year, today.month + 1)
      : DateTime(oldest.year, oldest.month);

  for (
    var month = DateTime(today.year, today.month);
    !month.isBefore(firstMonth);
    month = DateTime(month.year, month.month - 1)
  ) {
    for (final expense in expenses) {
      place(
        month,
        expense.startDate,
        expense.endDate,
        expense.frequencyEnum,
        (at) => JournalEntry(
          id: expense.id,
          source: JournalEntrySource.expense,
          type: TransactionType.expense,
          name: expense.name,
          amount: expense.amount,
          at: at,
          categorySlug: expense.categorySlug,
        ),
      );
    }

    for (final revenue in revenues) {
      place(
        month,
        revenue.startDate,
        revenue.endDate,
        revenue.frequencyEnum,
        (at) => JournalEntry(
          id: revenue.id,
          source: JournalEntrySource.revenue,
          type: TransactionType.income,
          name: revenue.name,
          amount: revenue.amount,
          at: at,
          categorySlug: revenue.categorySlug,
        ),
      );
    }
  }

  // A loan needs no recurrence rule : its schedule already holds every date
  // it was due on, and what was actually paid on each of them.
  for (final loan in loans) {
    for (final instalment in loan.schedule.installments) {
      final day = dayOnly(instalment.date);
      if (day.isAfter(today)) continue;

      final amount = instalment.totalPayment;
      if (amount <= 0) continue;

      byBucket
          .putIfAbsent(_bucketKeyOf(day, today), () => <JournalEntry>[])
          .add(
            JournalEntry(
              id: loan.id,
              source: JournalEntrySource.loan,
              type: TransactionType.expense,
              name: loan.name,
              amount: amount,
              at: instalment.date,
              categorySlug: kLoanCategorySlug,
            ),
          );
    }
  }

  final keys = byBucket.keys.toList()
    ..sort((a, b) {
      final byKind = a.kind.index.compareTo(b.kind.index);
      return byKind != 0 ? byKind : b.anchor.compareTo(a.anchor);
    });

  return [
    for (final key in keys)
      JournalBucket(
        kind: key.kind,
        anchor: key.anchor,
        entries: byBucket[key]!..sort((a, b) => b.at.compareTo(a.at)),
      ),
  ];
}

/// Today alone, for the figure above the list and for the hint that only
/// types itself out while the day is still bare.
@Riverpod(keepAlive: true)
List<JournalEntry> todayJournal(Ref ref) {
  final buckets = ref.watch(journalBucketsProvider);

  return buckets
          .where((bucket) => bucket.kind == JournalBucketKind.today)
          .firstOrNull
          ?.entries ??
      const <JournalEntry>[];
}

DateTime? _oldestStart(
  List<ExpenseModel> expenses,
  List<RevenueModel> revenues,
) {
  DateTime? oldest;

  void keep(DateTime candidate) {
    if (oldest == null || candidate.isBefore(oldest!)) oldest = candidate;
  }

  for (final expense in expenses) {
    keep(expense.startDate);
  }
  for (final revenue in revenues) {
    keep(revenue.startDate);
  }

  return oldest;
}

/// The Monday of the week [day] falls in.
DateTime startOfWeek(DateTime day) =>
    dayOnly(day).subtract(Duration(days: day.weekday - DateTime.monday));

/// Which slice a day belongs to. Resolution decays with distance : a day
/// while it is still remembered, then a week, then a month.
///
/// The week slices only ever cut the current month up. A month that had lost
/// its last days to "la semaine dernière" would show a total that is not the
/// month's, and a total you cannot trust is worse than a coarse one.
JournalBucketKind journalSliceOf(DateTime day, DateTime today) {
  if (day == today) return JournalBucketKind.today;
  if (day == today.subtract(const Duration(days: 1))) {
    return JournalBucketKind.yesterday;
  }

  final sameMonth = day.year == today.year && day.month == today.month;
  if (!sameMonth) return JournalBucketKind.month;

  final thisWeek = startOfWeek(today);
  if (!day.isBefore(thisWeek)) return JournalBucketKind.thisWeek;

  final lastWeek = thisWeek.subtract(const Duration(days: 7));
  if (!day.isBefore(lastWeek)) return JournalBucketKind.lastWeek;

  return JournalBucketKind.earlierThisMonth;
}

_BucketKey _bucketKeyOf(DateTime day, DateTime today) {
  final kind = journalSliceOf(day, today);

  return _BucketKey(kind, switch (kind) {
    JournalBucketKind.today || JournalBucketKind.yesterday => day,
    JournalBucketKind.thisWeek => startOfWeek(today),
    JournalBucketKind.lastWeek =>
      startOfWeek(today).subtract(const Duration(days: 7)),
    JournalBucketKind.earlierThisMonth ||
    JournalBucketKind.month => DateTime(day.year, day.month),
  });
}

/// The single day of [month] a transaction can land on : a recurring one
/// keeps its day of the month, a one-off only counts if it falls in it.
DateTime? _dayInMonth(
  DateTime startDate,
  Frequency frequency,
  DateTime month,
) {
  if (frequency == Frequency.oneTime) {
    final day = dayOnly(startDate);
    final sameMonth = day.year == month.year && day.month == month.month;
    return sameMonth ? day : null;
  }

  return DateTime(
    month.year,
    month.month,
    clampDayOfMonth(month.year, month.month, startDate.day),
  );
}

/// A recurring transaction keeps the hour it was created at but takes the
/// day's date : the line says when in the day it lands, not which month it
/// was first recorded in.
DateTime _occurrence(DateTime startDate, Frequency frequency, DateTime day) {
  if (frequency == Frequency.oneTime) return startDate;
  return DateTime(
    day.year,
    day.month,
    day.day,
    startDate.hour,
    startDate.minute,
  );
}

class _BucketKey {
  final JournalBucketKind kind;
  final DateTime anchor;

  const _BucketKey(this.kind, this.anchor);

  @override
  bool operator ==(Object other) =>
      other is _BucketKey && other.kind == kind && other.anchor == anchor;

  @override
  int get hashCode => Object.hash(kind, anchor);
}
