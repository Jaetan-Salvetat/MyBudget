import 'package:mybudget/core/enums/frequency.dart';

/// A date stripped of its hour, so two moments of the same day compare equal.
DateTime dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool isActiveForMonth(DateTime startDate, DateTime? endDate, DateTime month) {
  final startOfNextMonth = DateTime(month.year, month.month + 1);
  if (!startDate.isBefore(startOfNextMonth)) return false;
  final startOfMonth = DateTime(month.year, month.month, 1);
  if (endDate != null && endDate.isBefore(startOfMonth)) return false;
  return true;
}

/// Whether a rule lands on [month] at all : it has to be alive that month,
/// and its frequency has to bring it round.
///
/// This is the single answer to "does this count for this month ?" — the
/// lists and the totals both read it, so neither can drift from the other.
bool occursInMonth(
  DateTime startDate,
  DateTime? endDate,
  Frequency frequency,
  DateTime month,
) {
  if (!isActiveForMonth(startDate, endDate, month)) return false;

  switch (frequency) {
    case Frequency.monthly:
      return true;
    case Frequency.annual:
      return startDate.month == month.month;
    case Frequency.oneTime:
      return startDate.year == month.year && startDate.month == month.month;
  }
}

/// The date a rule lands on inside [month]. A recurring rule keeps the day it
/// started on, brought back to the last day of shorter months ; a one-off
/// keeps the moment it was recorded at.
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

DateTime computeEndDate(DateTime now, int paymentDay) {
  final clampedDay = clampDayOfMonth(now.year, now.month, paymentDay);
  if (now.day > clampedDay) {
    return DateTime(now.year, now.month, clampedDay);
  }
  final prevMonth = now.month == 1
      ? DateTime(now.year - 1, 12, 1)
      : DateTime(now.year, now.month - 1, 1);
  final clampedPrev = clampDayOfMonth(prevMonth.year, prevMonth.month, paymentDay);
  return DateTime(prevMonth.year, prevMonth.month, clampedPrev);
}

DateTime computeNewStartDate(DateTime now, int paymentDay) {
  final clampedDay = clampDayOfMonth(now.year, now.month, paymentDay);
  if (now.day > clampedDay) {
    final nextMonth = now.month == 12
        ? DateTime(now.year + 1, 1, 1)
        : DateTime(now.year, now.month + 1, 1);
    final clampedNext = clampDayOfMonth(nextMonth.year, nextMonth.month, paymentDay);
    return DateTime(nextMonth.year, nextMonth.month, clampedNext);
  }
  return DateTime(now.year, now.month, clampedDay);
}

/// The day of the month a recurring transaction lands on, brought back to the
/// last day when the month is too short for it.
int clampDayOfMonth(int year, int month, int day) {
  final maxDay = DateTime(year, month + 1, 0).day;
  return day > maxDay ? maxDay : day;
}

/// Whether a transaction falls on [day] : the day-level counterpart of
/// [isActiveForMonth]. A recurring transaction lands on the day of the month
/// it was started on, clamped to the last day of shorter months.
///
/// The bounds are read at day resolution, not month : a rule closed on the
/// 3rd never lands on the 15th of the month it closed in.
bool occursOnDay(
  DateTime startDate,
  DateTime? endDate,
  Frequency frequency,
  DateTime day,
) {
  final month = DateTime(day.year, day.month);
  if (!occursInMonth(startDate, endDate, frequency, month)) return false;

  if (dayOnly(day).isBefore(dayOnly(startDate))) return false;
  if (endDate != null && dayOnly(day).isAfter(dayOnly(endDate))) return false;

  return dayOnly(dayInMonthOf(startDate, frequency, month)) == dayOnly(day);
}
