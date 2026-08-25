/// Politique de décision du flow scan local.
///
/// règles (checksum) → classifieur argmax (re-checksum) → décodage sous
/// contrainte → retry prétraité (mêmes étages, garde-fou) → fusion des deux
/// passes → non vérifié. Le stage
/// n'est qu'un niveau d'information affiché à l'utilisateur : tout scan
/// atterrit sur l'écran d'édition pré-rempli (voir ml/scan/VERIFICATION.md).
/// Logique pure, sans I/O, alignée sur `ml/scan/test/analysis/local_flow.py`.
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
  });

  final FlowStage stage;
  final List<ExtractedItem> items;
  final double? total;

  bool get verified => verifiedStages.contains(stage);
}

/// Sauvetage à la demande d'un ticket que les règles n'ont pas vérifié :
/// n'est appelé que si local et retry ont échoué.
typedef Rescue = (FlowStage, ExtractedReceipt)? Function();

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
FlowOutcome _outcome(FlowStage stage, ExtractedReceipt receipt) => FlowOutcome(
  stage: stage,
  items: receipt.items,
  total: verifiedStages.contains(stage) ? receipt.verifiedTotal : receipt.total,
);

FlowOutcome decide(
  ExtractedReceipt local,
  ExtractedReceipt? retry,
  FlowPolicy policy, {
  Rescue? rescue,
}) {
  if (local.checksumOk) return _outcome(FlowStage.local, local);
  if (retry != null &&
      retry.checksumOk &&
      !_retryLosesValue(local, retry, policy)) {
    return _outcome(FlowStage.localRetry, retry);
  }
  if (rescue != null) {
    final rescued = rescue();
    if (rescued != null) return _outcome(rescued.$1, rescued.$2);
  }
  return _outcome(FlowStage.confirm, retry ?? local);
}

/// Sauvetage par le classifieur : argmax sur chaque passe, puis décodage
/// sous contrainte sur chaque passe. Toute sortie repasse par le checksum.
Rescue classifierRescue(
  List<List<PhysicalLine>> passes,
  LineClassifier classifier,
) {
  return () {
    final mergedPasses = [for (final pass in passes) mergedLines(pass)];
    for (final merged in mergedPasses) {
      final receipt = extractMl(merged, classifier);
      if (receipt != null && receipt.checksumOk) {
        return (FlowStage.localMl, receipt);
      }
    }
    for (final merged in mergedPasses) {
      final receipt = extractConstrained(merged, classifier);
      if (receipt != null && receipt.checksumOk) {
        return (FlowStage.localDp, receipt);
      }
    }
    return null;
  };
}

/// Dernier étage gratuit : les deux passes fusionnées ligne à ligne, le
/// décodeur arbitrant les montants qui diffèrent. Sortie re-checksummée.
ExtractedReceipt? fusedRescue(
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
  if (receipt != null && receipt.checksumOk) return receipt;
  return null;
}

/// Passe 1 seule : règles, puis classifieur (argmax, décodage sous
/// contrainte). Miroir de `decide_local` avant retry.
FlowOutcome decideFirstPass(
  ExtractedReceipt local,
  List<PhysicalLine> pass1,
  LineClassifier classifier,
  FlowPolicy policy,
) => decide(local, null, policy, rescue: classifierRescue([pass1], classifier));

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
    rescue: classifierRescue([retry], classifier),
  );
  if (outcome.verified) return outcome;
  final fused = fusedRescue(pass1, retry, classifier);
  return fused == null ? outcome : _outcome(FlowStage.localFused, fused);
}
