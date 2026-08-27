/// Le flow local : une lecture du ticket, un étiqueteur, une somme prouvée.
///
/// Il n'y a plus d'étages. La version précédente en enchaînait six — règles,
/// argmax du classifieur V2, décodage sous contrainte, tagger de rôles, sur
/// la passe 1 puis le retry puis leur fusion — chacun rattrapant ce que le
/// précédent ratait, le checksum arbitrant. Mesuré sur 483 tickets à vérité
/// golden (`bench/flows.py`), cet empilement rend **exactement le même
/// nombre de tickets justes** qu'un seul étiqueteur suivi d'un seul
/// décodeur : 341 contre 341. Ce qu'il ajoutait, c'étaient sept tickets
/// badgés « vérifié » de plus — et quatre tickets à montant faux de plus avec
/// eux. Il fabriquait de la confiance, pas de la justesse.
///
/// Ce qui reste :
///
///     lecture (passe 1 → retry → fusion, la suivante seulement si besoin)
///       → le tagger de rôles étiquette toutes les lignes
///       → le décodeur retient l'étiquetage le plus probable dont
///         Σ(articles − remises) tombe au centime sur une référence imprimée
///       → vérifié, ou écran de confirmation
///
/// Miroir de `ml/scan/research/reference/local_flow.py`.
library;

import 'decode_roles.dart';
import 'fuse_passes.dart';
import 'line_features.dart';
import 'lines.dart';
import 'role_tagger.dart' show predictedRoles;
import 'structure.dart';
import 'structure_roles.dart';

/// Quelle lecture de l'image a porté la somme prouvée. Ce n'est plus un
/// étage — il n'y en a qu'un — et [ReadSource.confirm] dit que rien ne l'a
/// prouvée.
enum ReadSource { pass1, retry, fused, confirm }

const Set<ReadSource> verifiedSources = {
  ReadSource.pass1,
  ReadSource.retry,
  ReadSource.fused,
};

/// L'étiquetage des lignes par le tagger de rôles — `RoleTagger.probabilities`
/// en production. Le flow ne connaît que cette signature : la politique de
/// lecture se teste sans modèle, et le modèle se change sans la toucher.
typedef RoleInference = List<List<double>> Function(List<PhysicalLine> lines);

/// Une lecture du ticket : les lignes telles que les modèles les ont
/// apprises, les mêmes avec les prix recollés, et — pour la fusion — les
/// montants que l'autre passe lit autrement.
///
/// Le tagger et le décodeur travaillent sur des lignes différentes et le rang
/// les aligne : [mergePriceFragments] recolle des mots *dans* une ligne,
/// jamais deux lignes entre elles.
class ReceiptRead {
  ReceiptRead(
    this.source,
    this.lines,
    this._inferRoles, {
    this.alternatives = const {},
  }) : merged = mergedLines(lines);

  final ReadSource source;
  final List<PhysicalLine> lines;
  final List<PhysicalLine> merged;
  final Map<int, int> alternatives;
  final RoleInference _inferRoles;

  List<List<double>>? _roles;

  /// Les probabilités de rôle, inférées une fois par lecture — c'est l'étage
  /// cher, et la fusion en redemande.
  List<List<double>> get roles => _roles ??= _inferRoles(lines);
}

/// Ce que le flow a lu, et par quelle lecture.
class LocalOutcome {
  const LocalOutcome({
    required this.source,
    required this.items,
    required this.total,
    required this.lines,
    required this.roles,
  });

  final ReadSource source;
  final List<ExtractedItem> items;
  final double? total;

  /// Les lignes dont l'extraction retenue est issue, et les rôles inférés
  /// dessus. `ExtractedItem.lineIndex` les indexe : rattacher un libellé sur
  /// les lignes d'une autre lecture désignerait n'importe quoi.
  final List<PhysicalLine> lines;
  final List<List<double>> roles;

  bool get verified => verifiedSources.contains(source);
}

/// Le reçu que cette lecture prouve, ou `null`.
ExtractedReceipt? readReceipt(ReceiptRead read) {
  final receipt = extractRoleConstrained(
    read.merged,
    read.roles,
    alternatives: read.alternatives,
  );
  return receipt != null && receipt.checksumOk ? receipt : null;
}

/// Ce qu'on affiche quand aucune somme n'est prouvée : l'argmax du tagger,
/// tel quel. Il pré-remplit l'écran de confirmation — et n'est jamais badgé
/// vérifié.
LocalOutcome unverified(ReceiptRead read) {
  final receipt = extractRoles(read.merged, predictedRoles(read.roles));
  return LocalOutcome(
    source: ReadSource.confirm,
    items: receipt?.items ?? const [],
    total: receipt?.total,
    lines: read.lines,
    roles: read.roles,
  );
}

LocalOutcome _verified(ReceiptRead read, ExtractedReceipt receipt) =>
    LocalOutcome(
      source: read.source,
      items: receipt.items,
      total: receipt.verifiedTotal,
      lines: read.lines,
      roles: read.roles,
    );

/// La seconde lecture de l'image, prétraitée. Elle ne coûte que sur les
/// tickets que la passe 1 ne prouve pas : le flow ne la demande qu'alors.
typedef SecondPass = Future<List<PhysicalLine>?> Function();

/// Les lectures, de la moins chère à la plus chère, jusqu'à ce que l'une
/// prouve la somme.
Future<LocalOutcome> decideLocal(
  List<PhysicalLine> pass1,
  RoleInference inferRoles, {
  SecondPass? secondPass,
}) async {
  final first = ReceiptRead(ReadSource.pass1, pass1, inferRoles);
  final proved = readReceipt(first);
  if (proved != null) return _verified(first, proved);
  if (secondPass == null) return unverified(first);

  final retryLines = await secondPass();
  if (retryLines == null || retryLines.isEmpty) return unverified(first);

  final retry = ReceiptRead(ReadSource.retry, retryLines, inferRoles);
  final retryProved = readReceipt(retry);
  if (retryProved != null) return _verified(retry, retryProved);

  final fusion = fusePasses(pass1, retryLines);
  final fused = ReceiptRead(
    ReadSource.fused,
    fusion.lines,
    inferRoles,
    alternatives: fusion.alternatives,
  );
  final fusedProved = readReceipt(fused);
  if (fusedProved != null) return _verified(fused, fusedProved);
  return unverified(fused);
}
