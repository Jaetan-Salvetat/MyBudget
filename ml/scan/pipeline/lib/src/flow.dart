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

/// Ce qu'une lecture a produit, gardé pour pouvoir l'expliquer.
///
/// Le flow en tente jusqu'à trois et n'en retient qu'une ; les deux autres
/// disparaissaient sans laisser de trace, et avec elles la seule chose qui
/// dit *pourquoi* la retenue l'a emporté. Rien ici n'est calculé pour
/// l'occasion : ce sont les objets que le décodage a déjà produits.
class ReadTrace {
  const ReadTrace({
    required this.source,
    required this.lines,
    required this.merged,
    required this.roles,
    required this.decoding,
  });

  final ReadSource source;
  final List<PhysicalLine> lines;
  final List<PhysicalLine> merged;
  final List<List<double>> roles;
  final ReceiptDecoding decoding;

  /// La somme est-elle retombée sur une référence imprimée ?
  bool get proved => decoding.receipt != null && decoding.receipt!.checksumOk;
}

/// Ce que le flow a lu, et par quelle lecture.
class LocalOutcome {
  const LocalOutcome({
    required this.source,
    required this.items,
    required this.total,
    required this.lines,
    required this.roles,
    this.trace = const [],
  });

  final ReadSource source;
  final List<ExtractedItem> items;
  final double? total;

  /// Les lignes dont l'extraction retenue est issue, et les rôles inférés
  /// dessus. `ExtractedItem.lineIndex` les indexe : rattacher un libellé sur
  /// les lignes d'une autre lecture désignerait n'importe quoi.
  final List<PhysicalLine> lines;
  final List<List<double>> roles;

  /// Les lectures tentées, dans l'ordre, jusqu'à celle qui a été retenue.
  /// Rien ne s'en sert pour décider — c'est de quoi rendre la décision
  /// lisible après coup.
  final List<ReadTrace> trace;

  bool get verified => verifiedSources.contains(source);
}

/// Ce que le décodeur fait de cette lecture.
ReadTrace traceOf(ReceiptRead read) => ReadTrace(
  source: read.source,
  lines: read.lines,
  merged: read.merged,
  roles: read.roles,
  decoding: decodeRoleConstrained(
    read.merged,
    read.roles,
    alternatives: read.alternatives,
  ),
);

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
LocalOutcome unverified(ReceiptRead read, {List<ReadTrace> trace = const []}) {
  final receipt = extractRoles(read.merged, predictedRoles(read.roles));
  return LocalOutcome(
    source: ReadSource.confirm,
    items: receipt?.items ?? const [],
    total: receipt?.total,
    lines: read.lines,
    roles: read.roles,
    trace: trace,
  );
}

LocalOutcome _verified(
  ReceiptRead read,
  ExtractedReceipt receipt,
  List<ReadTrace> trace,
) => LocalOutcome(
  source: read.source,
  items: receipt.items,
  total: receipt.verifiedTotal,
  lines: read.lines,
  roles: read.roles,
  trace: trace,
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
  final trace = <ReadTrace>[];

  /// Décode la lecture, l'archive, et rend le reçu seulement s'il prouve la
  /// somme. Une seule inférence et un seul décodage par lecture : la trace
  /// recueille ce que le flow calculait déjà.
  LocalOutcome? attempt(ReceiptRead read) {
    final step = traceOf(read);
    trace.add(step);
    return step.proved ? _verified(read, step.decoding.receipt!, trace) : null;
  }

  final first = ReceiptRead(ReadSource.pass1, pass1, inferRoles);
  final proved = attempt(first);
  if (proved != null) return proved;
  if (secondPass == null) return unverified(first, trace: trace);

  final retryLines = await secondPass();
  if (retryLines == null || retryLines.isEmpty) {
    return unverified(first, trace: trace);
  }

  final retry = ReceiptRead(ReadSource.retry, retryLines, inferRoles);
  final retryProved = attempt(retry);
  if (retryProved != null) return retryProved;

  final fusion = fusePasses(pass1, retryLines);
  final fused = ReceiptRead(
    ReadSource.fused,
    fusion.lines,
    inferRoles,
    alternatives: fusion.alternatives,
  );
  final fusedProved = attempt(fused);
  if (fusedProved != null) return fusedProved;
  return unverified(fused, trace: trace);
}
