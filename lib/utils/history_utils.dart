bool isActiveForMonth(DateTime startDate, DateTime? endDate, DateTime month) {
  final startOfNextMonth = DateTime(month.year, month.month + 1);
  if (!startDate.isBefore(startOfNextMonth)) return false;
  final startOfMonth = DateTime(month.year, month.month, 1);
  if (endDate != null && endDate.isBefore(startOfMonth)) return false;
  return true;
}

DateTime computeEndDate(DateTime now, int paymentDay) {
  final clampedDay = _clampDay(now.year, now.month, paymentDay);
  if (now.day > clampedDay) {
    return DateTime(now.year, now.month, clampedDay);
  }
  final prevMonth = now.month == 1
      ? DateTime(now.year - 1, 12, 1)
      : DateTime(now.year, now.month - 1, 1);
  final clampedPrev = _clampDay(prevMonth.year, prevMonth.month, paymentDay);
  return DateTime(prevMonth.year, prevMonth.month, clampedPrev);
}

DateTime computeNewStartDate(DateTime now, int paymentDay) {
  final clampedDay = _clampDay(now.year, now.month, paymentDay);
  if (now.day > clampedDay) {
    final nextMonth = now.month == 12
        ? DateTime(now.year + 1, 1, 1)
        : DateTime(now.year, now.month + 1, 1);
    final clampedNext = _clampDay(nextMonth.year, nextMonth.month, paymentDay);
    return DateTime(nextMonth.year, nextMonth.month, clampedNext);
  }
  return DateTime(now.year, now.month, clampedDay);
}

int _clampDay(int year, int month, int day) {
  final maxDay = DateTime(year, month + 1, 0).day;
  return day > maxDay ? maxDay : day;
}
