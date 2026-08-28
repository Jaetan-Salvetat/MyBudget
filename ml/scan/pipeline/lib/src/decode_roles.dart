/// Décodage sous contrainte guidé par le tagger de rôles.
///
/// Le décodeur cherche l'étiquetage le plus probable dont Σ(articles −
/// remises) tombe au centime sur une référence imprimée. Il consommait
/// jusqu'ici les probabilités du classifieur V2 : cinq classes, lignes
/// porteuses de prix seules, supervisé par les règles sur une seule enseigne.
///
/// Le tagger répond à la même question sur un corpus qui n'a plus rien à voir
/// — toutes les lignes, 2 827 tickets annotés depuis l'image, 337 enseignes —
/// et ses neuf rôles se projettent sur les cinq classes du décodeur. C'est la
/// seule chose qui change : mêmes invariants, même somme exacte, mêmes
/// montants recopiés de l'OCR.
///
/// Miroir de `ml/scan/research/reference/decode_roles.py`.
library;

import 'classifier.dart';
import 'decode.dart';
import 'line_features.dart';
import 'lines.dart';
import 'role_tagger.dart';
import 'structure.dart';
import 'structure_roles.dart';

/// Un rôle absent de cette table ne contribue à rien : il tombe dans
/// [labelIgnore], la classe fourre-tout du décodeur. `subtotal` rejoint
/// `total` — les deux sont des références de checksum, et le décodeur les
/// départage par sa propre éligibilité de rang, pas par leur nom.
const Map<String, int> roleToDecoderClass = {
  roleItem: labelItem,
  roleDiscount: labelDiscount,
  roleTotal: labelTotal,
  roleSubtotal: labelTotal,
  rolePayment: labelPayment,
};

const int decoderClasses = 5;

/// Les lignes auxquelles le tagger donne un rôle porteur de montant.
///
/// C'est là — et seulement là — que la lecture du prix s'élargit. L'argmax
/// suffit : aucun seuil n'est choisi à la main, un candidat de plus ne décide
/// de rien par lui-même, et c'est le checksum qui juge.
Set<int> laxRanks(List<List<double>> roleProbabilities) => {
  for (final (rank, row) in roleProbabilities.indexed)
    if (amountBearingRoles.contains(roleNames[argmax(row)])) rank,
};

/// Les probabilités du tagger, restreintes aux lignes chiffrées et repliées
/// sur les cinq classes du décodeur. Replier, c'est sommer : la probabilité
/// qu'une ligne soit une référence est celle qu'elle soit un total *ou* un
/// sous-total.
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

/// Ce que le décodeur a fait de cette lecture, et pas seulement ce qu'il en a
/// tiré.
///
/// Le reçu seul ne dit ni quelles lignes portaient un montant, ni lesquelles
/// la laxité a ouvertes, ni quel étiquetage a fait retomber la somme. Quand
/// une extraction surprend, c'est exactement ce qui manque pour comprendre —
/// et rien de tout ça ne coûte à calculer, c'est déjà fait.
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

/// Le reçu que ce ticket prouve, ou `null` si aucune somme ne retombe.
///
/// [merged] porte les prix recollés, et [roleProbabilities] décrit les lignes
/// telles que le tagger les a lues — les deux ont le même nombre de lignes,
/// le rang les aligne.
ExtractedReceipt? extractRoleConstrained(
  List<PhysicalLine> merged,
  List<List<double>> roleProbabilities, {
  Map<int, int> alternatives = const {},
}) => decodeRoleConstrained(
  merged,
  roleProbabilities,
  alternatives: alternatives,
).receipt;

/// Le même décodage, avec ce qu'il a traversé.
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
