import 'package:intl/intl.dart';
import 'package:mybudget/core/formatting/locales.dart';

abstract final class MoneyFormatter {
  static const String plusSign = '+';
  static const String minusSign = '−';
  static const String decimalSeparator = ',';
  static const String _currencySpace = '\u00A0';
  static const String currencySuffix =
      '$_currencySpace${FinancialLocale.currencySymbol}';
  static const int _centDigits = 2;
  static const int _wholeDigits = 0;
  static const String _missingDecimals = '00';

  static final NumberFormat _currency = NumberFormat.currency(
    locale: FinancialLocale.tag,
    symbol: FinancialLocale.currencySymbol,
    decimalDigits: _centDigits,
  );

  static final NumberFormat _roundedCurrency = NumberFormat.currency(
    locale: FinancialLocale.tag,
    symbol: FinancialLocale.currencySymbol,
    decimalDigits: _wholeDigits,
  );

  static final NumberFormat _plain = NumberFormat.decimalPatternDigits(
    locale: FinancialLocale.tag,
    decimalDigits: _centDigits,
  );

  static final NumberFormat _roundedPlain = NumberFormat.decimalPatternDigits(
    locale: FinancialLocale.tag,
    decimalDigits: _wholeDigits,
  );

  static String format(double amount) => _currency.format(amount);

  static String formatRounded(double amount) => _roundedCurrency.format(amount);

  static String formatPlain(double amount) => _plain.format(amount);

  static String formatPlainRounded(double amount) =>
      _roundedPlain.format(amount);

  static String signOf(double amount) =>
      amount.isNegative ? minusSign : plusSign;

  static String formatSigned(double amount) =>
      '${signOf(amount)} ${format(amount.abs())}';

  static ({String integer, String decimals}) splitParts(double amount) {
    final segments = formatPlain(amount.abs()).split(decimalSeparator);
    return (
      integer: segments.first,
      decimals: segments.length > 1 ? segments.last : _missingDecimals,
    );
  }
}
