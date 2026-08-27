/// Les lignes porteuses d'un prix — ce sur quoi le décodeur raisonne.
///
/// Un ticket se lit à deux granularités : toutes ses lignes, que le tagger de
/// rôles étiquette, et les seules lignes qui portent un montant, que le
/// décodeur combine pour retomber sur le total. [PricedLine] est cette
/// seconde vue, et son `index` est ce qui la rattache à la première.
///
/// Ce module portait aussi le featuriseur du classifieur de lignes V2/V3. Ce
/// classifieur est mort — mesuré sans effet sur le nombre de tickets justes,
/// et le tagger fait mieux ce qu'il faisait. Miroir de
/// `ml/scan/research/reference/line_features.py`.
library;

import 'lines.dart';
import 'structure.dart';

/// Une ligne fusionnée porteuse d'un prix, et sa place dans le ticket.
class PricedLine {
  const PricedLine({
    required this.index,
    required this.line,
    required this.price,
    required this.word,
  });

  final int index;
  final PhysicalLine line;
  final double price;
  final Word word;

  String get label => line.words
      .where((candidate) => !identical(candidate, word))
      .map((candidate) => candidate.text)
      .join(' ')
      .trim();
}

List<PricedLine> pricedLines(List<PhysicalLine> merged) => [
  for (final (index, line) in merged.indexed)
    if (rightmostPrice(line) case final priced?)
      PricedLine(
        index: index,
        line: line,
        price: priced.price,
        word: priced.word,
      ),
];

List<PhysicalLine> mergedLines(List<PhysicalLine> rawLines) => [
  for (final line in rawLines) mergePriceFragments(line),
];
