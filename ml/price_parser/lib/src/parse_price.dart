class PriceResult {
  final String fullText;

  final double price;

  final String remaining;

  const PriceResult({
    required this.fullText,
    required this.price,
    required this.remaining,
  });

  @override
  bool operator ==(Object other) =>
      other is PriceResult &&
      other.fullText == fullText &&
      other.price == price &&
      other.remaining == remaining;

  @override
  int get hashCode => Object.hash(fullText, price, remaining);

  @override
  String toString() =>
      'PriceResult(fullText: "$fullText", price: $price, remaining: "$remaining")';
}

final _currencySymbols = RegExp(r'[€$£]');

final _moneyWords = RegExp(
  r'\b(balles|euros?|dollars?|pounds?|bucks?)\b',
  caseSensitive: false,
);

final _thousandsSepFr = RegExp(
  r'(\d{1,3}(?:\s\d{3})+)(?:[,.](\d{2}))?',
);

final _thousandsSepEn = RegExp(
  r'(\d{1,3}(?:,\d{3})+)(?:\.(\d{1,2}))?',
);

final _decimalAmount = RegExp(
  r'(\d+)[,.](\d{1,2})\b',
);

final _integerAmount = RegExp(
  r'\d+',
);

PriceResult? parsePrice(String input) {
  if (input.trim().isEmpty) return null;

  final priceMatch = _findPrice(input);
  if (priceMatch == null) return null;

  final remaining = _buildRemaining(input, priceMatch);

  return PriceResult(
    fullText: input,
    price: priceMatch.value,
    remaining: remaining,
  );
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

_PriceMatch? _findPrice(String input) {
  final candidates = <_PriceMatch>[];

  for (final match in _thousandsSepFr.allMatches(input)) {
    final intPart = match.group(1)!.replaceAll(' ', '');
    final decPart = match.group(2);
    final value = decPart != null
        ? double.parse('$intPart.$decPart')
        : double.parse(intPart);
    candidates.add(_PriceMatch(value: value, start: match.start, end: match.end));
  }

  for (final match in _thousandsSepEn.allMatches(input)) {
    if (_isAlreadyCovered(candidates, match.start, match.end)) continue;
    final intPart = match.group(1)!.replaceAll(',', '');
    final decPart = match.group(2);
    final value = decPart != null
        ? double.parse('$intPart.$decPart')
        : double.parse(intPart);
    candidates.add(_PriceMatch(value: value, start: match.start, end: match.end));
  }

  for (final match in _decimalAmount.allMatches(input)) {
    if (_isAlreadyCovered(candidates, match.start, match.end)) continue;
    final intPart = match.group(1)!;
    final decPart = match.group(2)!;
    final value = double.parse('$intPart.$decPart');
    candidates.add(_PriceMatch(value: value, start: match.start, end: match.end));
  }

  for (final match in _integerAmount.allMatches(input)) {
    if (_isAlreadyCovered(candidates, match.start, match.end)) continue;
    final value = double.parse(match.group(0)!);
    candidates.add(_PriceMatch(value: value, start: match.start, end: match.end));
  }

  if (candidates.isEmpty) return null;

  if (candidates.length == 1) return candidates.first;

  return _selectBestCandidate(candidates, input);
}

_PriceMatch _selectBestCandidate(List<_PriceMatch> candidates, String input) {
  candidates.sort((a, b) => a.start.compareTo(b.start));
  return candidates.last;
}

bool _isAlreadyCovered(List<_PriceMatch> existing, int start, int end) {
  return existing.any((m) => start >= m.start && end <= m.end);
}

String _buildRemaining(String input, _PriceMatch priceMatch) {
  var result =
      '${input.substring(0, priceMatch.start)} ${input.substring(priceMatch.end)}';

  result = result.replaceAll(_currencySymbols, ' ');
  result = result.replaceAll(_moneyWords, ' ');
  result = result.replaceAll(RegExp(r'\s{2,}'), ' ');

  return result.trim();
}
