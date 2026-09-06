import 'package:mybudget/data/service/quick_add/date_parser_service.dart';
import 'package:mybudget/data/service/quick_add/price_parser_service.dart';

abstract final class QuickAddTextReader {
  static QuickAddTextFacts read(String input, {required DateTime today}) {
    final dateResult = DateParserService.parse(input, today: today);
    final withoutDate = dateResult?.remaining ?? input;

    final priceResult = PriceParserService.parse(withoutDate);
    final withoutAmount = priceResult?.remaining ?? withoutDate;

    return QuickAddTextFacts(
      input: input,
      date: dateResult?.date ?? _atMidnight(today),
      hasWrittenDate: dateResult != null,
      amount: priceResult?.price,
      remaining: withoutAmount.trim(),
    );
  }

  static DateTime _atMidnight(DateTime moment) =>
      DateTime(moment.year, moment.month, moment.day);
}

class QuickAddTextFacts {
  const QuickAddTextFacts({
    required this.input,
    required this.date,
    required this.hasWrittenDate,
    required this.amount,
    required this.remaining,
  });
  final String input;

  final DateTime date;

  final bool hasWrittenDate;

  final double? amount;

  final String remaining;

  String get modelText => remaining.isEmpty ? input : remaining;
}
