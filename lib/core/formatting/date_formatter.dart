import 'package:intl/intl.dart';
import 'package:mybudget/core/formatting/locales.dart';

abstract final class DateFormatter {
  static final DateFormat numericDate = _of('dd/MM/yyyy');
  static final DateFormat longDate = _of('d MMMM yyyy');
  static final DateFormat mediumDate = _of('d MMM yyyy');
  static final DateFormat dayMonth = _of('d MMMM');
  static final DateFormat shortDayMonth = _of('d MMM');
  static final DateFormat monthYear = _of('MMMM yyyy');
  static final DateFormat shortMonthYear = _of('MMM yyyy');
  static final DateFormat numericMonthYear = _of('MM/yyyy');
  static final DateFormat dayNumber = _of('d');
  static final DateFormat shortMonth = _of('MMM');
  static final DateFormat weekdayDay = _of('EEE d');
  static final DateFormat weekdayDayMonth = _of('EEE d MMM');
  static final DateFormat time = DateFormat.Hm(DisplayLocale.tag);

  static DateFormat _of(String pattern) =>
      DateFormat(pattern, DisplayLocale.tag);
}
