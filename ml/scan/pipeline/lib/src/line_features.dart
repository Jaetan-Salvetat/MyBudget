library;

import 'lines.dart';
import 'structure.dart';

class PricedLine {
  const PricedLine({
    required this.index,
    required this.line,
    required this.price,
    required this.word,
    this.candidates = const [],
  });

  final int index;
  final PhysicalLine line;
  final double price;
  final Word word;
  final List<double> candidates;

  String get label => line.words
      .where((candidate) => !identical(candidate, word))
      .map((candidate) => candidate.text)
      .join(' ')
      .trim();
}

List<PricedLine> pricedLines(
  List<PhysicalLine> merged, {
  Set<int> laxRanks = const {},
}) {
  final lines = <PricedLine>[];
  for (final (index, line) in merged.indexed) {
    final candidates = priceCandidates(line, lax: laxRanks.contains(index));
    if (candidates.isEmpty) continue;
    lines.add(
      PricedLine(
        index: index,
        line: line,
        price: candidates.first.price,
        word: candidates.first.word,
        candidates: [for (final candidate in candidates) candidate.price],
      ),
    );
  }
  return lines;
}

List<PhysicalLine> mergedLines(List<PhysicalLine> rawLines) => [
  for (final line in rawLines) mergePriceFragments(line),
];
