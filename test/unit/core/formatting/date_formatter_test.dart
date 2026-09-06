import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mybudget/core/formatting/date_formatter.dart';
import 'package:mybudget/core/formatting/locales.dart';

void main() {
  setUpAll(() => initializeDateFormatting(DisplayLocale.tag, null));

  final date = DateTime(2026, 3, 9, 14, 5);

  test('numericDate', () {
    expect(DateFormatter.numericDate.format(date), '09/03/2026');
  });

  test('longDate', () {
    expect(DateFormatter.longDate.format(date), '9 mars 2026');
  });

  test('mediumDate', () {
    expect(DateFormatter.mediumDate.format(date), '9 mars 2026');
  });

  test('dayMonth', () {
    expect(DateFormatter.dayMonth.format(date), '9 mars');
  });

  test('shortDayMonth', () {
    expect(DateFormatter.shortDayMonth.format(date), '9 mars');
  });

  test('monthYear', () {
    expect(DateFormatter.monthYear.format(date), 'mars 2026');
  });

  test('shortMonthYear', () {
    expect(DateFormatter.shortMonthYear.format(date), 'mars 2026');
  });

  test('numericMonthYear', () {
    expect(DateFormatter.numericMonthYear.format(date), '03/2026');
  });

  test('dayNumber', () {
    expect(DateFormatter.dayNumber.format(date), '9');
  });

  test('shortMonth', () {
    expect(DateFormatter.shortMonth.format(date), 'mars');
  });

  test('weekdayDay', () {
    expect(DateFormatter.weekdayDay.format(date), 'lun. 9');
  });

  test('weekdayDayMonth', () {
    expect(DateFormatter.weekdayDayMonth.format(date), 'lun. 9 mars');
  });

  test('time', () {
    expect(DateFormatter.time.format(date), '14:05');
  });
}
