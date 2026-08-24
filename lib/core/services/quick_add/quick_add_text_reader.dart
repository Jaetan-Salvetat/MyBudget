import 'package:mybudget/core/services/quick_add/date_parser_service.dart';
import 'package:mybudget/core/services/quick_add/price_parser_service.dart';

/// Everything a free-text entry states outright, read without a model.
///
/// Both engines and the live draft go through here, so the order the text is
/// taken apart in is decided once : the date first, then the amount on what is
/// left. The other way round, "essence 60 le 12" would be a 12 € expense.
abstract final class QuickAddTextReader {
  static QuickAddTextFacts read(String input, {DateTime? today}) {
    final dateResult = DateParserService.parse(input, today: today);
    final withoutDate = dateResult?.remaining ?? input;

    final priceResult = PriceParserService.parse(withoutDate);
    final withoutAmount = priceResult?.remaining ?? withoutDate;

    return QuickAddTextFacts(
      input: input,
      date: dateResult?.date ?? _atMidnight(today ?? DateTime.now()),
      hasWrittenDate: dateResult != null,
      amount: priceResult?.price,
      remaining: withoutAmount.trim(),
    );
  }

  static DateTime _atMidnight(DateTime moment) =>
      DateTime(moment.year, moment.month, moment.day);
}

class QuickAddTextFacts {
  /// The entry as it was typed.
  final String input;

  /// The day the transaction lands on, today when the text names none.
  final DateTime date;

  /// Whether [date] was read from the text rather than assumed.
  final bool hasWrittenDate;

  final double? amount;

  /// What is left once the date and the amount are taken out. Empty when the
  /// entry was nothing but numbers, and the name then comes from elsewhere.
  final String remaining;

  const QuickAddTextFacts({
    required this.input,
    required this.date,
    required this.hasWrittenDate,
    required this.amount,
    required this.remaining,
  });

  /// What the model reads. An entry that is nothing but its amount still has
  /// to be classified : an empty text would land in no category at all.
  String get modelText => remaining.isEmpty ? input : remaining;
}
