import 'package:flutter/foundation.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

import 'local_flow.dart';

/// Photographie immuable des statistiques : c'est elle que les widgets
/// reçoivent — une nouvelle instance par notification, donc un rebuild
/// garanti (un widget `const` identique ne serait jamais reconstruit).
class SessionSnapshot {
  const SessionSnapshot({
    required this.byStage,
    required this.total,
    required this.verified,
    required this.retries,
    required this.failures,
    required this.medianLatencyMs,
    required this.p95LatencyMs,
  });

  final Map<FlowStage, int> byStage;
  final int total;
  final int verified;
  final int retries;
  final int failures;
  final int? medianLatencyMs;
  final int? p95LatencyMs;

  double get verifiedRate => total == 0 ? 0.0 : verified / total;

  bool get isEmpty => total == 0 && failures == 0;
}

/// Statistiques cumulées de la session de test, tous modes confondus
/// (suite, galerie, caméra) : répartition des étages, taux vérifié, retries,
/// latences, échecs techniques. Mise à jour au fil des tickets.
class SessionStats extends ChangeNotifier {
  final Map<FlowStage, int> _byStage = {
    for (final stage in FlowStage.values) stage: 0,
  };
  final List<int> _latenciesMs = [];
  int _retries = 0;
  int _failures = 0;

  Map<FlowStage, int> get byStage => Map.unmodifiable(_byStage);

  int get total => _byStage.values.fold(0, (sum, count) => sum + count);

  int get verified =>
      verifiedStages.fold(0, (sum, stage) => sum + _byStage[stage]!);

  double get verifiedRate => total == 0 ? 0.0 : verified / total;

  int get retries => _retries;

  int get failures => _failures;

  int? get medianLatencyMs => _percentile(0.5);

  int? get p95LatencyMs => _percentile(0.95);

  SessionSnapshot get snapshot => SessionSnapshot(
    byStage: byStage,
    total: total,
    verified: verified,
    retries: retries,
    failures: failures,
    medianLatencyMs: medianLatencyMs,
    p95LatencyMs: p95LatencyMs,
  );

  int? _percentile(double fraction) {
    if (_latenciesMs.isEmpty) return null;
    final sorted = [..._latenciesMs]..sort();
    final position = (sorted.length * fraction).floor();
    return sorted[position.clamp(0, sorted.length - 1)];
  }

  void record(LocalScanResult result) {
    _byStage[result.outcome.stage] = _byStage[result.outcome.stage]! + 1;
    if (result.retryUsed) _retries++;
    _latenciesMs.add(result.totalLatencyMs);
    notifyListeners();
  }

  void recordFailure() {
    _failures++;
    notifyListeners();
  }

  void reset() {
    _byStage.updateAll((_, _) => 0);
    _latenciesMs.clear();
    _retries = 0;
    _failures = 0;
    notifyListeners();
  }
}

/// Une session = une instance : chaque écran y contribue et la consulte.
final SessionStats sessionStats = SessionStats();
