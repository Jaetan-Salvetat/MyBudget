import 'package:mybudget/core/enums/effective_month.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/recurring_deletion.dart';

DateTime dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool isActiveForMonth(DateTime startDate, DateTime? endDate, DateTime month) {
  final startOfNextMonth = DateTime(month.year, month.month + 1);
  if (!startDate.isBefore(startOfNextMonth)) return false;
  final startOfMonth = DateTime(month.year, month.month, 1);
  if (endDate != null && endDate.isBefore(startOfMonth)) return false;
  return true;
}

bool occursInMonth(
  DateTime startDate,
  DateTime? endDate,
  Frequency frequency,
  DateTime month,
) {
  if (!isActiveForMonth(startDate, endDate, month)) return false;

  switch (frequency) {
    case Frequency.oneTime:
      return startDate.year == month.year && startDate.month == month.month;
    case Frequency.annual:
      if (startDate.month != month.month) return false;
    case Frequency.monthly:
      break;
  }

  final landing = dayInMonthOf(startDate, frequency, month);
  if (landing.isBefore(dayOnly(startDate))) return false;
  return endDate == null || !landing.isAfter(dayOnly(endDate));
}

DateTime dayInMonthOf(
  DateTime startDate,
  Frequency frequency,
  DateTime month,
) {
  if (frequency == Frequency.oneTime) return startDate;

  return DateTime(
    month.year,
    month.month,
    clampDayOfMonth(month.year, month.month, startDate.day),
  );
}

bool hasOccurredThisMonth(
  DateTime startDate,
  DateTime? endDate,
  Frequency frequency,
  DateTime asOf,
) {
  final month = DateTime(asOf.year, asOf.month);
  if (!occursInMonth(startDate, endDate, frequency, month)) return false;

  return !dayInMonthOf(startDate, frequency, month).isAfter(dayOnly(asOf));
}

DateTime closingDateOf(
  RecurringDeletion scope,
  DateTime startDate,
  Frequency frequency,
  DateTime asOf,
) {
  switch (scope) {
    case RecurringDeletion.afterThisMonth:
      return dayOnly(asOf);
    case RecurringDeletion.includingThisMonth:
      final due = dayInMonthOf(
        startDate,
        frequency,
        DateTime(asOf.year, asOf.month),
      );
      return dayOnly(due).subtract(const Duration(days: 1));
  }
}

bool hasStarted(DateTime startDate, DateTime asOf) =>
    !dayOnly(startDate).isAfter(dayOnly(asOf));

DateTime startDateFor({
  required Frequency frequency,
  required DateTime anchor,
  required DateTime asOf,
  required EffectiveMonth scope,
}) {
  switch (frequency) {
    case Frequency.oneTime:
      return anchor;
    case Frequency.annual:
      return _nextAnniversaryOf(anchor, asOf);
    case Frequency.monthly:
      return _dueDateIn(_monthOf(scope, asOf), anchor.day);
  }
}

bool offersEffectiveMonthChoice(Frequency frequency) =>
    frequency == Frequency.monthly;

EffectiveMonth defaultEffectiveMonth({
  required Frequency frequency,
  required DateTime anchor,
  required DateTime asOf,
}) {
  if (!offersEffectiveMonthChoice(frequency)) return EffectiveMonth.thisMonth;

  final due = _dueDateIn(DateTime(asOf.year, asOf.month), anchor.day);
  return due.isBefore(dayOnly(asOf))
      ? EffectiveMonth.nextMonth
      : EffectiveMonth.thisMonth;
}

bool sameSchedule(DateTime a, DateTime b, Frequency frequency) {
  switch (frequency) {
    case Frequency.oneTime:
      return dayOnly(a) == dayOnly(b);
    case Frequency.annual:
      return a.month == b.month && a.day == b.day;
    case Frequency.monthly:
      return a.day == b.day;
  }
}

DateTime _monthOf(EffectiveMonth scope, DateTime asOf) {
  return switch (scope) {
    EffectiveMonth.thisMonth => DateTime(asOf.year, asOf.month),
    EffectiveMonth.nextMonth => DateTime(asOf.year, asOf.month + 1),
  };
}

DateTime _dueDateIn(DateTime month, int day) {
  return DateTime(
    month.year,
    month.month,
    clampDayOfMonth(month.year, month.month, day),
  );
}

DateTime _nextAnniversaryOf(DateTime anchor, DateTime asOf) {
  final thisYear = _dueDateIn(DateTime(asOf.year, anchor.month), anchor.day);
  if (!thisYear.isBefore(dayOnly(asOf))) return thisYear;
  return _dueDateIn(DateTime(asOf.year + 1, anchor.month), anchor.day);
}

int clampDayOfMonth(int year, int month, int day) {
  final maxDay = DateTime(year, month + 1, 0).day;
  return day > maxDay ? maxDay : day;
}

bool occursOnDay(
  DateTime startDate,
  DateTime? endDate,
  Frequency frequency,
  DateTime day,
) {
  final month = DateTime(day.year, day.month);
  if (!occursInMonth(startDate, endDate, frequency, month)) return false;

  return dayOnly(dayInMonthOf(startDate, frequency, month)) == dayOnly(day);
}

RecurringDeletion? initialDeletionScopeOf(
  DateTime startDate,
  DateTime? endDate,
  Frequency frequency,
  DateTime asOf,
) {
  if (frequency == Frequency.oneTime) return null;

  return hasOccurredThisMonth(startDate, endDate, frequency, asOf)
      ? RecurringDeletion.afterThisMonth
      : RecurringDeletion.includingThisMonth;
}
