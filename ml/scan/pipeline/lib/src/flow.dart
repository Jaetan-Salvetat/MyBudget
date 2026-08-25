/// Politique de décision du flow scan local.
///
/// règles (checksum) → classifieur argmax (re-checksum) → décodage sous
/// contrainte → retry prétraité (mêmes étages, garde-fou) → fusion des deux
/// passes → non vérifié. Le stage
/// n'est qu'un niveau d'information affiché à l'utilisateur : tout scan
/// atterrit sur l'écran d'édition pré-rempli (voir ml/scan/VERIFICATION.md).
/// Logique pure, sans I/O, alignée sur `ml/scan/research/reference/local_flow.py`.
library;

import 'classifier.dart';
import 'decode.dart';
import 'fuse_passes.dart';
import 'line_features.dart';
import 'lines.dart';
import 'structure.dart';

enum FlowStage { local, localRetry, localMl, localDp, localFused, confirm }

/// Stages dont la sortie a passé le checksum : badge « vérifié » côté UI.
const Set<FlowStage> verifiedStages = {
  FlowStage.local,
  FlowStage.localRetry,
  FlowStage.localMl,
  FlowStage.localDp,
  FlowStage.localFused,
};

class FlowPolicy {
  const FlowPolicy({
    this.tolerance = 0.005,
    this.retryMustNotLoseValue = false,
  });

  /// Politique retenue par le bench : garde-fou retry actif, tolérance
  /// stricte.
  static const FlowPolicy recommended = FlowPolicy(retryMustNotLoseValue: true);

  final double tolerance;
  final bool retryMustNotLoseValue;
}

class FlowOutcome {
  const FlowOutcome({
    required this.stage,
    required this.items,
    required this.total,
    required this.sourceLines,
  });

  final FlowStage stage;
  final List<ExtractedItem> items;
  final double? total;

  /// Les lignes dont l'extraction retenue est issue. `ExtractedItem.lineIndex`
  /// les indexe : le flow peut retenir la passe 1, le retry ou leur fusion,
  /// et rien d'autre ne dit laquelle. Sans elles, rattacher un libellé
  /// désignerait la ligne d'une autre passe.
  final List<PhysicalLine> sourceLines;

  bool get verified => verifiedStages.contains(stage);
}

/// Sauvetage à la demande d'un ticket que les règles n'ont pas vérifié :
/// n'est appelé que si local et retry ont échoué.
typedef Rescue = (FlowStage, ExtractedReceipt, List<PhysicalLine>)? Function();

/// Un retry qui somme moins que la passe 1 a perdu des articles : son
/// checksum peut passer par collision de substitution sur le total (vu sur
/// corpus), on l'envoie en confirmation plutôt que de valider en silence.
bool _retryLosesValue(
  ExtractedReceipt local,
  ExtractedReceipt retry,
  FlowPolicy policy,
) {
  if (!policy.retryMustNotLoseValue) return false;
  if (_sameTotal(local, retry, policy)) return false;
  return retry.itemsSum < local.itemsSum - policy.tolerance;
}

/// Même total lu par les deux passes : la référence n'a pas bougé, la
/// valeur perdue était un article parasite de la passe 1, pas une collision.
bool _sameTotal(
  ExtractedReceipt local,
  ExtractedReceipt retry,
  FlowPolicy policy,
) {
  final localTotal = local.total;
  final retryTotal = retry.total;
  return localTotal != null &&
      retryTotal != null &&
      (localTotal - retryTotal).abs() <= policy.tolerance;
}

/// Un étage vérifié affiche la référence qui a réellement vérifié la somme ;
/// la confirmation pré-remplit avec le total lu, faux ou non.
FlowOutcome _outcome(
  FlowStage stage,
  ExtractedReceipt receipt,
  List<PhysicalLine> sourceLines,
) => FlowOutcome(
  stage: stage,
  items: receipt.items,
  total: verifiedStages.contains(stage) ? receipt.verifiedTotal : receipt.total,
  sourceLines: sourceLines,
);

FlowOutcome decide(
  ExtractedReceipt local,
  ExtractedReceipt? retry,
  FlowPolicy policy, {
  // Vide par défaut : un appelant qui ne fournit pas les lignes obtient un
  // résultat sans `sourceLines`, donc pas de rattachement de libellé — jamais
  // un rattachement sur les lignes d'une autre passe. Les tests de décision
  // pure s'en passent, le flow de l'app les fournit.
  List<PhysicalLine> localLines = const [],
  List<PhysicalLine>? retryLines,
  Rescue? rescue,
}) {
  if (local.checksumOk) return _outcome(FlowStage.local, local, localLines);
  if (retry != null &&
      retry.checksumOk &&
      !_retryLosesValue(local, retry, policy)) {
    return _outcome(FlowStage.localRetry, retry, retryLines ?? localLines);
  }
  if (rescue != null) {
    final rescued = rescue();
    if (rescued != null) return _outcome(rescued.$1, rescued.$2, rescued.$3);
  }
  final fallback = retry ?? local;
  return _outcome(
    FlowStage.confirm,
    fallback,
    retry != null ? (retryLines ?? localLines) : localLines,
  );
}

/// Sauvetage par le classifieur : argmax sur chaque passe, puis décodage
/// sous contrainte sur chaque passe. Toute sortie repasse par le checksum.
Rescue classifierRescue(
  List<List<PhysicalLine>> passes,
  LineClassifier classifier,
) {
  return () {
    final mergedPasses = [for (final pass in passes) mergedLines(pass)];
    for (var index = 0; index < mergedPasses.length; index++) {
      final receipt = extractMl(mergedPasses[index], classifier);
      if (receipt != null && receipt.checksumOk) {
        return (FlowStage.localMl, receipt, passes[index]);
      }
    }
    for (var index = 0; index < mergedPasses.length; index++) {
      final receipt = extractConstrained(mergedPasses[index], classifier);
      if (receipt != null && receipt.checksumOk) {
        return (FlowStage.localDp, receipt, passes[index]);
      }
    }
    return null;
  };
}

/// Dernier étage gratuit : les deux passes fusionnées ligne à ligne, le
/// décodeur arbitrant les montants qui diffèrent. Sortie re-checksummée.
(ExtractedReceipt, List<PhysicalLine>)? fusedRescue(
  List<PhysicalLine> pass1,
  List<PhysicalLine> retry,
  LineClassifier classifier,
) {
  final fused = fusePasses(pass1, retry);
  final receipt = extractConstrained(
    mergedLines(fused.lines),
    classifier,
    alternatives: fused.alternatives,
  );
  if (receipt != null && receipt.checksumOk) return (receipt, fused.lines);
  return null;
}

/// Passe 1 seule : règles, puis classifieur (argmax, décodage sous
/// contrainte). Miroir de `decide_local` avant retry.
FlowOutcome decideFirstPass(
  ExtractedReceipt local,
  List<PhysicalLine> pass1,
  LineClassifier classifier,
  FlowPolicy policy,
) => decide(
  local,
  null,
  policy,
  localLines: pass1,
  rescue: classifierRescue([pass1], classifier),
);

/// Après un retry : mêmes étages sur la passe prétraitée, puis fusion des
/// deux passes si rien ne vérifie. Miroir de `decide_local` après retry.
FlowOutcome decideRetryPass(
  ExtractedReceipt local,
  ExtractedReceipt retryReceipt,
  List<PhysicalLine> pass1,
  List<PhysicalLine> retry,
  LineClassifier classifier,
  FlowPolicy policy,
) {
  final outcome = decide(
    local,
    retryReceipt,
    policy,
    localLines: pass1,
    retryLines: retry,
    rescue: classifierRescue([retry], classifier),
  );
  if (outcome.verified) return outcome;
  final fused = fusedRescue(pass1, retry, classifier);
  if (fused == null) return outcome;
  return _outcome(FlowStage.localFused, fused.$1, fused.$2);
}
