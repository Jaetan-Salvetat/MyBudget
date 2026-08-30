library;

import 'dart:math' as math;

const double minVerticalOverlapRatio = 0.4;

const double baselineSplitRatio = 0.6;

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

double medianAngle(List<double> lineAngles) {
  if (lineAngles.isEmpty) return 0.0;
  final sorted = [...lineAngles]..sort();
  return sorted[sorted.length ~/ 2];
}

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

List<T> _stableSortedBy<T>(List<T> values, double Function(T) key) {
  final indexed = values.asMap().entries.toList()
    ..sort((a, b) {
      final byKey = key(a.value).compareTo(key(b.value));
      return byKey != 0 ? byKey : a.key.compareTo(b.key);
    });
  return [for (final entry in indexed) entry.value];
}

List<double> _baselineResiduals(List<Word> words) {
  final xs = [for (final word in words) (word.left + word.right) / 2];
  final ys = [for (final word in words) word.centerY];
  final meanX = xs.reduce((a, b) => a + b) / xs.length;
  final meanY = ys.reduce((a, b) => a + b) / ys.length;
  var variance = 0.0;
  var covariance = 0.0;
  for (var index = 0; index < words.length; index++) {
    variance += (xs[index] - meanX) * (xs[index] - meanX);
    covariance += (xs[index] - meanX) * (ys[index] - meanY);
  }
  final slope = variance == 0 ? 0.0 : covariance / variance;
  return [
    for (var index = 0; index < words.length; index++)
      ys[index] - (meanY + slope * (xs[index] - meanX)),
  ];
}

double _medianHeight(List<Word> words) {
  final heights = [for (final word in words) word.bottom - word.top]..sort();
  return heights[heights.length ~/ 2];
}

List<List<Word>> splitBaselines(List<Word> words) {
  if (words.length < 2) return [words];
  final residuals = _baselineResiduals(words);
  final gap = baselineSplitRatio * _medianHeight(words);
  final order = _stableSortedBy(
    [for (var index = 0; index < words.length; index++) index],
    (index) => residuals[index],
  );
  final groups = <List<Word>>[[]];
  int? previous;
  for (final index in order) {
    if (previous != null && residuals[index] - residuals[previous] > gap) {
      groups.add([]);
    }
    groups.last.add(words[index]);
    previous = index;
  }
  return groups;
}

List<PhysicalLine> clusterLines(List<Word> words, {bool split = true}) {
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
      for (final group in split ? splitBaselines(clusterWords) : [clusterWords])
        PhysicalLine(words: _stableSortedBy(group, (w) => w.left)),
  ];
  return _stableSortedBy(result, (line) => line.top);
}
