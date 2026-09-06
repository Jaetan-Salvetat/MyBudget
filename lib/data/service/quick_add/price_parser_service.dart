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

  static final RegExp _letter = RegExp(r'[a-zA-ZÀ-ÿ]');

  /// Une quantité porte son unité, un montant n'en porte pas : « forfait 100
  /// Go » n'a pas de prix, et le retirer laissait « forfait Go » au modèle.
  static final RegExp _trailingUnit = RegExp(
    r'^\s?(?:go|mo|ko|to|gb|mb|kb|tb|kg|mg|cl|ml|km|cm|mm|min|g|l|m|h|j|jours?|semaines?|mois|ans?)\b',
    caseSensitive: false,
  );

  static PriceParseResult? parse(String input) {
    if (input.trim().isEmpty) return null;

    final priceMatch = _findPrice(input);
    if (priceMatch == null) return null;

    return PriceParseResult(
      price: priceMatch.value,
      remaining: _buildRemaining(input, priceMatch),
    );
  }

  /// Ce que la saisie désigne par un nombre n'est pas toujours un montant.
  ///
  /// Collé à des lettres, il fait partie du nom — « SP98 », « A10 », « S24 » ;
  /// suivi d'une unité, c'est une quantité. Dans les deux cas le retirer
  /// ampute le texte que lit le modèle, et « plein de SP » ne ressemble plus à
  /// du carburant.
  static bool _isAnAmount(String input, int start, int end) {
    if (start > 0 && _letter.hasMatch(input[start - 1])) return false;
    if (end < input.length && _letter.hasMatch(input[end])) return false;
    return !_trailingUnit.hasMatch(input.substring(end));
  }

  static _PriceMatch? _findPrice(String input) {
    final candidates = <_PriceMatch>[];

    for (final match in _thousandsSepFr.allMatches(input)) {
      if (!_isAnAmount(input, match.start, match.end)) continue;
      final intPart = match.group(1)!.replaceAll(' ', '');
      final decPart = match.group(2);
      final value = decPart != null
          ? double.parse('$intPart.$decPart')
          : double.parse(intPart);
      candidates.add(
        _PriceMatch(value: value, start: match.start, end: match.end),
      );
    }

    for (final match in _thousandsSepEn.allMatches(input)) {
      if (_isAlreadyCovered(candidates, match.start, match.end)) continue;
      if (!_isAnAmount(input, match.start, match.end)) continue;
      final intPart = match.group(1)!.replaceAll(',', '');
      final decPart = match.group(2);
      final value = decPart != null
          ? double.parse('$intPart.$decPart')
          : double.parse(intPart);
      candidates.add(
        _PriceMatch(value: value, start: match.start, end: match.end),
      );
    }

    for (final match in _decimalAmount.allMatches(input)) {
      if (_isAlreadyCovered(candidates, match.start, match.end)) continue;
      if (!_isAnAmount(input, match.start, match.end)) continue;
      final value = double.parse('${match.group(1)!}.${match.group(2)!}');
      candidates.add(
        _PriceMatch(value: value, start: match.start, end: match.end),
      );
    }

    for (final match in _integerAmount.allMatches(input)) {
      if (_isAlreadyCovered(candidates, match.start, match.end)) continue;
      if (!_isAnAmount(input, match.start, match.end)) continue;
      final value = double.parse(match.group(0)!);
      candidates.add(
        _PriceMatch(value: value, start: match.start, end: match.end),
      );
    }

    if (candidates.isEmpty) return null;
    if (candidates.length == 1) return candidates.first;

    candidates.sort((a, b) => a.start.compareTo(b.start));
    return candidates.last;
  }

  static bool _isAlreadyCovered(
    List<_PriceMatch> existing,
    int start,
    int end,
  ) {
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
  const PriceParseResult({required this.price, required this.remaining});
  final double price;
  final String remaining;
}

class _PriceMatch {
  const _PriceMatch({
    required this.value,
    required this.start,
    required this.end,
  });
  final double value;
  final int start;
  final int end;
}
