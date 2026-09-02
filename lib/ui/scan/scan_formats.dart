import 'package:intl/intl.dart';

final NumberFormat scanCurrency = NumberFormat.currency(
  locale: 'fr_FR',
  symbol: '€',
  decimalDigits: 2,
);

final DateFormat scanDate = DateFormat('d MMMM yyyy', 'fr_FR');
