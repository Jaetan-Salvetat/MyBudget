abstract final class TextNormalizer {
  static final RegExp _whitespace = RegExp(r'\s+');

  static const Map<String, String> _diacritics = {
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'á': 'a',
    'ã': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'í': 'i',
    'ô': 'o',
    'ö': 'o',
    'ó': 'o',
    'õ': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ú': 'u',
    'ç': 'c',
    'ñ': 'n',
  };

  static String normalize(String text) {
    var result = text.toLowerCase().trim();
    for (final entry in _diacritics.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result.replaceAll(_whitespace, ' ');
  }
}
