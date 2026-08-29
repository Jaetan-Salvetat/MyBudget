import 'package:mybudget/core/enums/frequency.dart';

bool isActiveForMonth(DateTime startDate, DateTime? endDate, DateTime month) {
  final startOfNextMonth = DateTime(month.year, month.month + 1);
  if (!startDate.isBefore(startOfNextMonth)) return false;
  final startOfMonth = DateTime(month.year, month.month, 1);
  if (endDate != null && endDate.isBefore(startOfMonth)) return false;
  return true;
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
bool occursOnDay(
  DateTime startDate,
  DateTime? endDate,
  Frequency frequency,
  DateTime day,
) {
  if (!isActiveForMonth(startDate, endDate, DateTime(day.year, day.month))) {
    return false;
  }

  switch (frequency) {
    case Frequency.oneTime:
      return startDate.year == day.year &&
          startDate.month == day.month &&
          startDate.day == day.day;
    case Frequency.monthly:
      return clampDayOfMonth(day.year, day.month, startDate.day) == day.day;
    case Frequency.annual:
      return startDate.month == day.month &&
          clampDayOfMonth(day.year, day.month, startDate.day) == day.day;
  }
}
