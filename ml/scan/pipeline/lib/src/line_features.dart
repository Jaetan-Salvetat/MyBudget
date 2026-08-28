/// Les lignes porteuses d'un prix — ce sur quoi le décodeur raisonne.
///
/// Un ticket se lit à deux granularités : toutes ses lignes, que le tagger de
/// rôles étiquette, et les seules lignes qui portent un montant, que le
/// décodeur combine pour retomber sur le total. [PricedLine] est cette
/// seconde vue, et son `index` est ce qui la rattache à la première.
///
/// Une ligne y entre avec **tous** ses montants plausibles, pas un seul. La
/// lecture principale reste la lecture stricte ; les autres sont là pour que
/// le décodeur puisse en préférer une quand c'est elle qui fait retomber la
/// somme.
///
/// Ce module portait aussi le featuriseur du classifieur de lignes V2/V3. Ce
/// classifieur est mort — mesuré sans effet sur le nombre de tickets justes,
/// et le tagger fait mieux ce qu'il faisait. Miroir de
/// `ml/scan/research/reference/line_features.py`.
library;

import 'lines.dart';
import 'structure.dart';

/// Une ligne fusionnée porteuse d'un prix, et sa place dans le ticket.
///
/// [price] est la lecture principale ; [candidates] les montants que la ligne
/// peut porter, celle-ci en tête.
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

/// Les lignes porteuses d'un montant. Une ligne y entre avec **tous** ses
/// montants plausibles ; quelles lignes ont droit à cette largeur est décidé
/// par le tagger, pas ici — [laxRanks] porte sa réponse.
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
