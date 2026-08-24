/// Politique de décision du flow scan complet.
///
/// local (checksum) → retry prétraité (checksum) → écran de confirmation
/// pré-rempli. L'étage cloud de `decide` sert aux benchs historiques : le
/// mode produit est local seul (voir ml/scan/VERIFICATION.md).
/// Logique pure, sans I/O, alignée sur `ml/scan/test/analysis/flow.py` et
/// calibrée par `bench_flow.py` : 0 faux auto-validé sur corpus avec le
/// garde-fou retry actif.
library;

import 'structure.dart';

enum FlowStage { local, localRetry, cloud, confirm }

const Set<FlowStage> autoStages = {
  FlowStage.local,
  FlowStage.localRetry,
  FlowStage.cloud,
};

enum ConfirmPrefill { cloud, local }

class FlowPolicy {
  const FlowPolicy({
    this.tolerance = 0.005,
    this.crossCheckLocalTotal = false,
    this.confirmPrefill = ConfirmPrefill.cloud,
    this.retryMustNotLoseValue = false,
  });

  /// Politique retenue par le bench : garde-fou retry actif, tolérance
  /// stricte, pré-remplissage cloud.
  static const FlowPolicy recommended =
      FlowPolicy(retryMustNotLoseValue: true);

  final double tolerance;
  final bool crossCheckLocalTotal;
  final ConfirmPrefill confirmPrefill;
  final bool retryMustNotLoseValue;
}

class CloudReceipt {
  const CloudReceipt({required this.items, required this.total});

  final List<ExtractedItem> items;
  final double? total;

  double get itemsSum => roundCents(
        items.fold(0.0, (sum, item) => sum + item.amount - item.discount),
      );
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
}

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

bool cloudAccepts(
  CloudReceipt cloud,
  double? localTotal,
  FlowPolicy policy,
) {
  final cloudTotal = cloud.total;
  if (cloudTotal == null) return false;
  if ((cloud.itemsSum - cloudTotal).abs() > policy.tolerance) return false;
  if (policy.crossCheckLocalTotal &&
      localTotal != null &&
      (cloudTotal - localTotal).abs() > policy.tolerance) {
    return false;
  }
  return true;
}

double? _localTotal(ExtractedReceipt local, ExtractedReceipt? retry) =>
    local.total ?? retry?.total;

FlowOutcome decide(
  ExtractedReceipt local,
  ExtractedReceipt? retry,
  CloudReceipt? cloud,
  FlowPolicy policy,
) {
  if (local.checksumOk) {
    return FlowOutcome(
      stage: FlowStage.local,
      items: local.items,
      total: local.total,
    );
  }
  if (retry != null &&
      retry.checksumOk &&
      !_retryLosesValue(local, retry, policy)) {
    return FlowOutcome(
      stage: FlowStage.localRetry,
      items: retry.items,
      total: retry.total,
    );
  }

  if (cloud != null &&
      cloudAccepts(cloud, _localTotal(local, retry), policy)) {
    return FlowOutcome(
      stage: FlowStage.cloud,
      items: cloud.items,
      total: cloud.total,
    );
  }

  if (cloud != null && policy.confirmPrefill == ConfirmPrefill.cloud) {
    return FlowOutcome(
      stage: FlowStage.confirm,
      items: cloud.items,
      total: cloud.total,
    );
  }
  final bestLocal = retry ?? local;
  return FlowOutcome(
    stage: FlowStage.confirm,
    items: bestLocal.items,
    total: bestLocal.total,
  );
}
