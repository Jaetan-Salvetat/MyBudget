import 'package:intl/intl.dart';
import 'package:mybudget/models/expense_model.dart';

enum ExpenseGroupBy {
  day,
  week;

  String get label => switch (this) {
    ExpenseGroupBy.day => 'Jour',
    ExpenseGroupBy.week => 'Semaine',
  };

  static ExpenseGroupBy fromName(String? value) {
    return ExpenseGroupBy.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExpenseGroupBy.day,
    );
  }
}

class ExpenseDayGroup {
  final DateTime date;
  final List<ExpenseModel> items;

  const ExpenseDayGroup({required this.date, required this.items});

  double get total => items.fold(0, (s, e) => s + e.amount);
}

class ExpenseWeekGroup {
  final int weekNumber;
  final DateTime weekStart;
  final DateTime weekEnd;
  final List<ExpenseModel> items;

  const ExpenseWeekGroup({
    required this.weekNumber,
    required this.weekStart,
    required this.weekEnd,
    required this.items,
  });

  double get total => items.fold(0, (s, e) => s + e.amount);
}

class ExpenseGroupingService {
  const ExpenseGroupingService._();

  static List<ExpenseDayGroup> groupByDay(
    List<ExpenseModel> expenses, {
    bool descending = true,
  }) {
    final map = <DateTime, List<ExpenseModel>>{};
    for (final expense in expenses) {
      final key = DateTime(
        expense.startDate.year,
        expense.startDate.month,
        expense.startDate.day,
      );
      map.putIfAbsent(key, () => []).add(expense);
    }
    final groups = map.entries
        .map((e) => ExpenseDayGroup(date: e.key, items: e.value))
        .toList();
    groups.sort(
      (a, b) =>
          descending ? b.date.compareTo(a.date) : a.date.compareTo(b.date),
    );
    return groups;
  }

  static List<ExpenseWeekGroup> groupByWeek(
    List<ExpenseModel> expenses,
    DateTime selectedMonth, {
    bool descending = true,
  }) {
    final firstDayOfMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    );
    final map = <int, List<ExpenseModel>>{};

    for (final expense in expenses) {
      final weekIndex = ((expense.startDate.day - 1) ~/ 7).clamp(0, 4);
      map.putIfAbsent(weekIndex, () => []).add(expense);
    }

    final groups = map.entries.map((entry) {
      final weekIndex = entry.key;
      final startDay = weekIndex * 7 + 1;
      final endDay = startDay + 6;
      final lastDayOfMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + 1,
        0,
      ).day;
      final start = DateTime(
        firstDayOfMonth.year,
        firstDayOfMonth.month,
        startDay,
      );
      final end = DateTime(
        firstDayOfMonth.year,
        firstDayOfMonth.month,
        endDay > lastDayOfMonth ? lastDayOfMonth : endDay,
      );
      final weekNumber = _isoWeekNumber(start);
      return ExpenseWeekGroup(
        weekNumber: weekNumber,
        weekStart: start,
        weekEnd: end,
        items: entry.value,
      );
    }).toList();

    groups.sort(
      (a, b) => descending
          ? b.weekStart.compareTo(a.weekStart)
          : a.weekStart.compareTo(b.weekStart),
    );
    return groups;
  }

  static List<double> weeklyTotals(
    List<ExpenseModel> expenses,
    DateTime selectedMonth,
  ) {
    final lastDay = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;
    final weekCount = ((lastDay - 1) ~/ 7) + 1;
    final buckets = List<double>.filled(weekCount, 0);
    for (final expense in expenses) {
      final index = ((expense.startDate.day - 1) ~/ 7).clamp(0, weekCount - 1);
      buckets[index] += expense.amount;
    }
    return buckets;
  }

  static int _isoWeekNumber(DateTime date) {
    final thursday = date.add(
      Duration(days: 4 - ((date.weekday == 7) ? 7 : date.weekday)),
    );
    final firstThursday = DateTime(thursday.year, 1, 4);
    final firstThursdayDayOfWeek = firstThursday.weekday;
    final firstWeekStart = firstThursday.subtract(
      Duration(days: firstThursdayDayOfWeek - 1),
    );
    final diff = thursday.difference(firstWeekStart).inDays;
    return (diff ~/ 7) + 1;
  }
}

extension DateLabelExtension on DateTime {
  String get dayHeaderLabel {
    final formatter = DateFormat("EEE d MMM", 'fr_FR');
    final formatted = formatter.format(this);
    return formatted.replaceAll('.', '.').toUpperCase();
  }
}
