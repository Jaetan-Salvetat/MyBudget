import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/rules/recurrence_rules.dart';
import 'package:mybudget/core/values/loan.dart';
import 'package:mybudget/data/model/expense_model.dart';
import 'package:mybudget/data/model/revenue_model.dart';
import 'package:mybudget/data/provider/loan_queries.dart';
import 'package:mybudget/data/provider/loans_provider.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/ui/capture/models/journal_bucket.dart';
import 'package:mybudget/ui/capture/models/journal_entry.dart';
import 'package:mybudget/ui/shared/expense_queries.dart';
import 'package:mybudget/ui/shared/revenue_queries.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'capture_provider.g.dart';

const String kLoanCategorySlug = 'finance.credit_pret';

@Riverpod(keepAlive: true)
double remainingThisMonth(Ref ref) {
  return ref.watch(currentMonthRevenuesProvider) -
      ref.watch(currentMonthExpensesProvider) -
      ref.watch(totalMonthlyLoanPaymentsProvider);
}

@Riverpod(keepAlive: true)
List<JournalBucket> journalBuckets(Ref ref) {
  final expenses = ref.watch(expenseHistoryProvider);
  final revenues = ref.watch(revenueHistoryProvider);
  final loans = ref.watch(loanProvider).value ?? const <Loan>[];
  final today = dayOnly(ref.watch(clockProvider)());

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

DateTime startOfWeek(DateTime day) =>
    dayOnly(day).subtract(Duration(days: day.weekday - DateTime.monday));

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
    JournalBucketKind.lastWeek => startOfWeek(
      today,
    ).subtract(const Duration(days: 7)),
    JournalBucketKind.earlierThisMonth ||
    JournalBucketKind.month => DateTime(day.year, day.month),
  });
}

DateTime? _dayInMonth(DateTime startDate, Frequency frequency, DateTime month) {
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
  const _BucketKey(this.kind, this.anchor);
  final JournalBucketKind kind;
  final DateTime anchor;

  @override
  bool operator ==(Object other) =>
      other is _BucketKey && other.kind == kind && other.anchor == anchor;

  @override
  int get hashCode => Object.hash(kind, anchor);
}
