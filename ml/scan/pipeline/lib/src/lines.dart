/// Reconstruit les lignes physiques d'un ticket depuis la sortie ML Kit.
///
/// ML Kit regroupe le texte en blocs/lignes selon sa propre logique de
/// paragraphe, qui casse les colonnes des tickets (libellé à gauche, prix à
/// droite). On repart des éléments (mots) et on re-clusterise par
/// recouvrement vertical des boîtes.
library;

import 'dart:math' as math;

const double minVerticalOverlapRatio = 0.4;

class Word {
  const Word({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.confidence,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;
  final double? confidence;

  double get centerY => (top + bottom) / 2;

  double get height => bottom - top;
}

class PhysicalLine {
  const PhysicalLine({required this.words});

  final List<Word> words;

  String get text => words.map((word) => word.text).join(' ');

  double get top => words.map((word) => word.top).reduce(math.min);

  double get bottom => words.map((word) => word.bottom).reduce(math.max);

  double? get minConfidence {
    final scores = [
      for (final word in words)
        if (word.confidence != null) word.confidence!,
    ];
    return scores.isEmpty ? null : scores.reduce(math.min);
  }
}

/// Angle dominant du texte en degrés, tel que mesuré par ML Kit ligne par
/// ligne. Zéro quand aucun angle n'est disponible (iOS).
double medianAngle(List<double> lineAngles) {
  if (lineAngles.isEmpty) return 0.0;
  final sorted = [...lineAngles]..sort();
  return sorted[sorted.length ~/ 2];
}

/// Tourne les boîtes de -angle autour de l'origine pour ramener les lignes à
/// l'horizontale avant le clustering. Sans ça, une photo inclinée de 4°
/// décale la colonne des prix d'une ligne et demie en haut du ticket.
List<Word> deskewWords(List<Word> words, double angleDegrees) {
  if (angleDegrees.abs() < 0.2) return words;
  final radians = -angleDegrees * math.pi / 180;
  final cos = math.cos(radians);
  final sin = math.sin(radians);

  return [for (final word in words) _rotated(word, cos, sin)];
}

Word _rotated(Word word, double cos, double sin) {
  final x = (word.left + word.right) / 2;
  final y = (word.top + word.bottom) / 2;
  final centerX = x * cos - y * sin;
  final centerY = x * sin + y * cos;
  final halfWidth = (word.right - word.left) / 2;
  final halfHeight = (word.bottom - word.top) / 2;
  return Word(
    text: word.text,
    left: centerX - halfWidth,
    top: centerY - halfHeight,
    right: centerX + halfWidth,
    bottom: centerY + halfHeight,
    confidence: word.confidence,
  );
}

double _verticalOverlapRatio(Word word, double lineTop, double lineBottom) {
  final overlap =
      math.min(word.bottom, lineBottom) - math.max(word.top, lineTop);
  if (overlap <= 0) return 0.0;
  return overlap / math.min(word.height, lineBottom - lineTop);
}

/// Tri stable requis : deux mots au même ordonné doivent garder leur ordre
/// d'arrivée pour reproduire le clustering de référence (List.sort ne le
/// garantit pas).
List<T> _stableSortedBy<T>(List<T> values, double Function(T) key) {
  final indexed = values.asMap().entries.toList()
    ..sort((a, b) {
      final byKey = key(a.value).compareTo(key(b.value));
      return byKey != 0 ? byKey : a.key.compareTo(b.key);
    });
  return [for (final entry in indexed) entry.value];
}

List<PhysicalLine> clusterLines(List<Word> words) {
  final ordered = _stableSortedBy(words, (word) => word.centerY);
  final clusters = <List<Word>>[];
  for (final word in ordered) {
    var placed = false;
    for (final clusterWords in clusters) {
      final lineTop = clusterWords.map((w) => w.top).reduce(math.min);
      final lineBottom = clusterWords.map((w) => w.bottom).reduce(math.max);
      if (_verticalOverlapRatio(word, lineTop, lineBottom) >=
          minVerticalOverlapRatio) {
        clusterWords.add(word);
        placed = true;
        break;
      }
    }
    if (!placed) clusters.add([word]);
  }
  final result = [
    for (final clusterWords in clusters)
      PhysicalLine(words: _stableSortedBy(clusterWords, (w) => w.left)),
  ];
  return _stableSortedBy(result, (line) => line.top);
}
