library;

import 'structure.dart' show foldAccents, levenshtein;

const int minContainedLength = 5;


const int fuzzyCharsPerEdit = 6;
const int fuzzyMaxEdits = 3;

final RegExp _nonAlphanumeric = RegExp(r'[^A-Z0-9 ]+');

String normalizeStore(String text) {
  final folded = foldAccents(text.toUpperCase());
  return folded.replaceAll(_nonAlphanumeric, ' ').split(' ')
      .where((part) => part.isNotEmpty)
      .join(' ');
}

int _tolerance(String entry) {
  final budget = entry.length ~/ fuzzyCharsPerEdit;
  return budget < fuzzyMaxEdits ? budget : fuzzyMaxEdits;
}

bool fuzzyContains(String line, String entry) {
  final budget = _tolerance(entry);
  if (budget == 0) return false;
  final words = line.split(' ');
  for (var start = 0; start < words.length; start++) {
    var window = '';
    for (var end = start; end < words.length; end++) {
      window = window.isEmpty ? words[end] : '$window ${words[end]}';
      if (window.length > entry.length + budget) break;
      final gap = (window.length - entry.length).abs();
      if (gap <= budget && levenshtein(window, entry) <= budget) return true;
    }
  }
  return false;
}

class Gazetteer {
  Gazetteer(this.canonical)
    : keys = canonical.keys.toList()
        ..sort((a, b) => b.length.compareTo(a.length));

  final Map<String, String> canonical;
  final List<String> keys;

  String? match(String text) {
    final line = normalizeStore(text);
    if (line.isEmpty) return null;
    for (final key in keys) {
      if (key == line) return canonical[key];
    }
    for (final key in keys) {
      if (key.length >= minContainedLength && line.contains(key)) {
        return canonical[key];
      }
    }
    for (final key in keys) {
      if (key.length >= minContainedLength && fuzzyContains(line, key)) {
        return canonical[key];
      }
    }
    return null;
  }
}
