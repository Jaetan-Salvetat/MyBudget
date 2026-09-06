import 'package:intl/intl.dart';
import 'package:mybudget/core/formatting/locales.dart';

abstract final class PercentFormatter {
  static const String symbol = '%';
  static const String _symbolSpace = '\u00A0';
  static const int _rateDigits = 2;
  static const int _wholeDigits = 0;
  static const double _pointsPerUnit = 100;

  static final NumberFormat _rate = NumberFormat.decimalPatternDigits(
    locale: DisplayLocale.tag,
    decimalDigits: _rateDigits,
  );

  static final NumberFormat _whole = NumberFormat.decimalPatternDigits(
    locale: DisplayLocale.tag,
    decimalDigits: _wholeDigits,
  );

  static String formatRate(double points) => _suffixed(_rate.format(points));

  static String formatWhole(num points) => _suffixed(_whole.format(points));

  static String formatShare(double share) =>
      formatWhole((share * _pointsPerUnit).round());

  static String _suffixed(String value) => '$value$_symbolSpace$symbol';
}
