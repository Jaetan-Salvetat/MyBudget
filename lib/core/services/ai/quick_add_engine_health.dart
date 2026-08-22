import 'package:mybudget/core/enums/ai_request_failure.dart';
import 'package:mybudget/core/services/preferences_service.dart';

/// Compte les échecs du moteur distant pour décider quand repasser en local.
/// Une clé révoquée dégrade tout de suite ; le reste attend le seuil, parce
/// qu'un réseau qui tremble n'est pas une panne.
class QuickAddEngineHealth {
  QuickAddEngineHealth({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const int failureThreshold = 3;
  static const Duration window = Duration(hours: 24);

  final DateTime Function() _now;

  bool get isDegraded => _recentFailures().length >= failureThreshold;

  /// True quand cet échec vient de faire basculer le moteur : c'est le seul
  /// moment où l'utilisateur est prévenu.
  Future<bool> recordFailure(AiRequestFailure failure) async {
    final wasDegraded = isDegraded;

    if (failure.revokesKey) {
      await _persist(
        List.filled(failureThreshold, _now().millisecondsSinceEpoch),
      );
      return !wasDegraded;
    }

    await _persist([..._recentFailures(), _now().millisecondsSinceEpoch]);
    return !wasDegraded && isDegraded;
  }

  Future<void> recordSuccess() async {
    if (PreferencesService.getAiFailureTimestamps().isEmpty) return;
    await _persist(const []);
  }

  Future<void> reset() => _persist(const []);

  List<int> _recentFailures() {
    final horizon = _now().subtract(window).millisecondsSinceEpoch;
    return PreferencesService.getAiFailureTimestamps()
        .where((timestamp) => timestamp >= horizon)
        .toList();
  }

  Future<void> _persist(List<int> timestamps) =>
      PreferencesService.setAiFailureTimestamps(timestamps);
}
