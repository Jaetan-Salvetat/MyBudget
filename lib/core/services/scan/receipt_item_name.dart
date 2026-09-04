const String _leadingMarkers = '*#-•.·';

final RegExp _whitespace = RegExp(r'\s+');
final RegExp _lowercase = RegExp('[a-zà-öø-ÿ]');
final RegExp _digit = RegExp(r'\d');
final RegExp _letter = RegExp('[a-zA-Zà-öø-ÿÀ-ÖØ-Þ]');

String receiptItemDisplayName(String raw) {
  final trimmed = _stripMarkers(raw).replaceAll(_whitespace, ' ').trim();
  if (trimmed.isEmpty) return '';
  if (_lowercase.hasMatch(trimmed)) return trimmed;

  final tokens = trimmed
      .split(' ')
      .map((token) => _digit.hasMatch(token) ? token : token.toLowerCase())
      .toList();

  final first = tokens.indexWhere((token) => !_digit.hasMatch(token));
  if (first >= 0) tokens[first] = _capitalizeFirstLetter(tokens[first]);

  return tokens.join(' ');
}

String _stripMarkers(String raw) {
  var start = 0;
  while (start < raw.length &&
      (_leadingMarkers.contains(raw[start]) || raw[start].trim().isEmpty)) {
    start++;
  }
  return raw.substring(start);
}

String _capitalizeFirstLetter(String value) {
  final index = value.indexOf(_letter);
  if (index < 0) return value;

  return value.substring(0, index) +
      value[index].toUpperCase() +
      value.substring(index + 1);
}
