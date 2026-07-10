abstract final class PriceParserService {
  static final RegExp _currencySymbols = RegExp(r'[€$£]');

  static final RegExp _moneyWords = RegExp(
    r'\b(balles|euros?|dollars?|pounds?|bucks?)\b',
    caseSensitive: false,
  );

  static final RegExp _thousandsSepFr = RegExp(
    r'(\d{1,3}(?:\s\d{3})+)(?:[,.](\d{2}))?',
  );

  static final RegExp _thousandsSepEn = RegExp(
    r'(\d{1,3}(?:,\d{3})+)(?:\.(\d{1,2}))?',
  );

  static final RegExp _decimalAmount = RegExp(r'(\d+)[,.](\d{1,2})\b');

  static final RegExp _integerAmount = RegExp(r'\d+');

  static PriceParseResult? parse(String input) {
    if (input.trim().isEmpty) return null;

    final priceMatch = _findPrice(input);
    if (priceMatch == null) return null;

    return PriceParseResult(
      price: priceMatch.value,
      remaining: _buildRemaining(input, priceMatch),
    );
  }

  static _PriceMatch? _findPrice(String input) {
    final candidates = <_PriceMatch>[];

    for (final match in _thousandsSepFr.allMatches(input)) {
      final intPart = match.group(1)!.replaceAll(' ', '');
      final decPart = match.group(2);
      final value = decPart != null
          ? double.parse('$intPart.$decPart')
          : double.parse(intPart);
      candidates
          .add(_PriceMatch(value: value, start: match.start, end: match.end));
    }

    for (final match in _thousandsSepEn.allMatches(input)) {
      if (_isAlreadyCovered(candidates, match.start, match.end)) continue;
      final intPart = match.group(1)!.replaceAll(',', '');
      final decPart = match.group(2);
      final value = decPart != null
          ? double.parse('$intPart.$decPart')
          : double.parse(intPart);
      candidates
          .add(_PriceMatch(value: value, start: match.start, end: match.end));
    }

    for (final match in _decimalAmount.allMatches(input)) {
      if (_isAlreadyCovered(candidates, match.start, match.end)) continue;
      final value = double.parse('${match.group(1)!}.${match.group(2)!}');
      candidates
          .add(_PriceMatch(value: value, start: match.start, end: match.end));
    }

    for (final match in _integerAmount.allMatches(input)) {
      if (_isAlreadyCovered(candidates, match.start, match.end)) continue;
      final value = double.parse(match.group(0)!);
      candidates
          .add(_PriceMatch(value: value, start: match.start, end: match.end));
    }

    if (candidates.isEmpty) return null;
    if (candidates.length == 1) return candidates.first;

    candidates.sort((a, b) => a.start.compareTo(b.start));
    return candidates.last;
  }

  static bool _isAlreadyCovered(List<_PriceMatch> existing, int start, int end) {
    return existing.any((m) => start >= m.start && end <= m.end);
  }

  static String _buildRemaining(String input, _PriceMatch priceMatch) {
    var result =
        '${input.substring(0, priceMatch.start)} ${input.substring(priceMatch.end)}';

    result = result.replaceAll(_currencySymbols, ' ');
    result = result.replaceAll(_moneyWords, ' ');
    result = result.replaceAll(RegExp(r'\s{2,}'), ' ');

    return result.trim();
  }
}

class PriceParseResult {
  final double price;
  final String remaining;

  const PriceParseResult({required this.price, required this.remaining});
}

class _PriceMatch {
  final double value;
  final int start;
  final int end;

  const _PriceMatch({
    required this.value,
    required this.start,
    required this.end,
  });
}
