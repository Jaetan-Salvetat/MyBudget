import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/capture/models/journal_day.dart';
import 'package:mybudget/ui/capture/models/journal_entry.dart';
import 'package:mybudget/ui/expenses/expense_queries.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/loans/loan_queries.dart';
import 'package:mybudget/ui/revenues/revenue_queries.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/utils/history_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'capture_provider.g.dart';

/// What the month has left once everything it already owes is counted. The
/// capture screen shows that figure and nothing else : it is the consequence
/// of what was just typed, not a summary of the month.
@Riverpod(keepAlive: true)
double remainingThisMonth(Ref ref) {
  return ref.watch(currentMonthRevenuesProvider) -
      ref.watch(currentMonthExpensesProvider) -
      ref.watch(totalMonthlyLoanPaymentsProvider);
}

/// The month so far, newest day first and newest line first inside each day.
/// The journal opens on what just happened and scrolls back through the
/// month ; days with nothing on them are left out rather than drawn empty.
@Riverpod(keepAlive: true)
List<JournalDay> monthJournal(Ref ref) {
  final expenses = ref.watch(expenseProvider).value ?? const <ExpenseModel>[];
  final revenues = ref.watch(revenueProvider).value ?? const <RevenueModel>[];
  final today = dayOnly(DateTime.now());

  final byDay = <DateTime, List<JournalEntry>>{};

  void place(
    DateTime startDate,
    DateTime? endDate,
    Frequency frequency,
    JournalEntry Function(DateTime at) build,
  ) {
    final day = _dayInMonth(startDate, frequency, today);
    if (day == null || day.isAfter(today)) return;
    if (!occursOnDay(startDate, endDate, frequency, day)) return;

    byDay
        .putIfAbsent(day, () => <JournalEntry>[])
        .add(build(_occurrence(startDate, frequency, day)));
  }

  for (final expense in expenses) {
    place(
      expense.startDate,
      expense.endDate,
      expense.frequencyEnum,
      (at) => JournalEntry(
        id: expense.id,
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
      revenue.startDate,
      revenue.endDate,
      revenue.frequencyEnum,
      (at) => JournalEntry(
        id: revenue.id,
        type: TransactionType.income,
        name: revenue.name,
        amount: revenue.amount,
        at: at,
        categorySlug: revenue.categorySlug,
      ),
    );
  }

  final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

  return [
    for (final day in days)
      JournalDay(
        day: day,
        entries: byDay[day]!..sort((a, b) => b.at.compareTo(a.at)),
      ),
  ];
}

/// Today alone, for the figure above the list and for the hint that only
/// types itself out while the day is still bare.
@Riverpod(keepAlive: true)
List<JournalEntry> todayJournal(Ref ref) {
  final today = dayOnly(DateTime.now());
  final days = ref.watch(monthJournalProvider);

  return days
          .where((journalDay) => journalDay.isSameDay(today))
          .firstOrNull
          ?.entries ??
      const <JournalEntry>[];
}

DateTime dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

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
