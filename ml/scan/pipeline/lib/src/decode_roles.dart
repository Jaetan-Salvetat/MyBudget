library;

import 'classifier.dart';
import 'decode.dart';
import 'line_features.dart';
import 'lines.dart';
import 'role_tagger.dart';
import 'structure.dart';
import 'structure_roles.dart';

const Map<String, int> roleToDecoderClass = {
  roleItem: labelItem,
  roleDiscount: labelDiscount,
  roleTotal: labelTotal,
  roleSubtotal: labelTotal,
  rolePayment: labelPayment,
};

const int decoderClasses = 5;

Set<int> laxRanks(List<List<double>> roleProbabilities) => {
  for (final (rank, row) in roleProbabilities.indexed)
    if (amountBearingRoles.contains(roleNames[argmax(row)])) rank,
};

List<List<double>> decoderProbabilities(
  List<List<double>> roleProbabilities,
  List<PricedLine> priced,
) => [
  for (final line in priced)
    if (line.index >= roleProbabilities.length)
      (List<double>.filled(decoderClasses, 0.0)..[labelIgnore] = 1.0)
    else
      _folded(roleProbabilities[line.index]),
];

List<double> _folded(List<double> row) {
  final folded = List<double>.filled(decoderClasses, 0.0);
  for (final (column, role) in roleNames.indexed) {
    final target = roleToDecoderClass[role] ?? labelIgnore;
    folded[target] += row[column];
  }
  return folded;
}

class ReceiptDecoding {
  const ReceiptDecoding({
    required this.laxRanks,
    required this.priced,
    required this.hypothesis,
    required this.receipt,
  });

  final Set<int> laxRanks;
  final List<PricedLine> priced;
  final Hypothesis? hypothesis;
  final ExtractedReceipt? receipt;
}

ExtractedReceipt? extractRoleConstrained(
  List<PhysicalLine> merged,
  List<List<double>> roleProbabilities, {
  Map<int, int> alternatives = const {},
}) => decodeRoleConstrained(
  merged,
  roleProbabilities,
  alternatives: alternatives,
).receipt;

ReceiptDecoding decodeRoleConstrained(
  List<PhysicalLine> merged,
  List<List<double>> roleProbabilities, {
  Map<int, int> alternatives = const {},
}) {
  final lax = laxRanks(roleProbabilities);
  final priced = pricedLines(merged, laxRanks: lax);
  if (priced.isEmpty) {
    return ReceiptDecoding(
      laxRanks: lax,
      priced: priced,
      hypothesis: null,
      receipt: null,
    );
  }
  final hypothesis = decodeConstrained(
    priced,
    decoderProbabilities(roleProbabilities, priced),
    printedCount: printedCount(merged),
    alternatives: rankAlternatives(priced, alternatives),
  );
  return ReceiptDecoding(
    laxRanks: lax,
    priced: priced,
    hypothesis: hypothesis,
    receipt: hypothesis == null ? null : _receiptOf(merged, priced, hypothesis),
  );
}

ExtractedReceipt? _receiptOf(
  List<PhysicalLine> merged,
  List<PricedLine> priced,
  Hypothesis hypothesis,
) {
  final referenceTotal = hypothesis.referenceCents / 100;
  if (hypothesis.singleItem) return singleItemReceipt(merged, referenceTotal);
  final chosen = hypothesis.cents.isEmpty
      ? priced
      : withChosenAmounts(priced, hypothesis.labels, hypothesis.cents);
  return receiptFromLabels(
    merged,
    chosen,
    hypothesis.labels,
    referenceTotal: referenceTotal,
  );
}
