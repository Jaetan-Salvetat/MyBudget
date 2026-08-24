/// Politique de décision du flow scan local.
///
/// règles (checksum) → retry prétraité (checksum, garde-fou) → classifieur
/// argmax (re-checksum) → décodage sous contrainte → non vérifié. Le stage
/// n'est qu'un niveau d'information affiché à l'utilisateur : tout scan
/// atterrit sur l'écran d'édition pré-rempli (voir ml/scan/VERIFICATION.md).
/// Logique pure, sans I/O, alignée sur `ml/scan/test/analysis/local_flow.py`.
library;

import 'classifier.dart';
import 'decode.dart';
import 'line_features.dart';
import 'lines.dart';
import 'structure.dart';

enum FlowStage { local, localRetry, localMl, localDp, confirm }

/// Stages dont la sortie a passé le checksum : badge « vérifié » côté UI.
const Set<FlowStage> verifiedStages = {
  FlowStage.local,
  FlowStage.localRetry,
  FlowStage.localMl,
  FlowStage.localDp,
};

class FlowPolicy {
  const FlowPolicy({
    this.tolerance = 0.005,
    this.retryMustNotLoseValue = false,
  });

  /// Politique retenue par le bench : garde-fou retry actif, tolérance
  /// stricte.
  static const FlowPolicy recommended =
      FlowPolicy(retryMustNotLoseValue: true);

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
  return retry.itemsSum < local.itemsSum - policy.tolerance;
}

FlowOutcome _outcome(FlowStage stage, ExtractedReceipt receipt) =>
    FlowOutcome(stage: stage, items: receipt.items, total: receipt.total);

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
