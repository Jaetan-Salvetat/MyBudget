import 'package:mybudget/core/enums/ai_request_failure.dart';
import 'package:mybudget/core/services/quick_add/quick_add_classification.dart';
import 'package:mybudget/core/services/quick_add/quick_add_engine.dart';

/// Le moteur embarqué part à chaque saisie, même quand le distant est actif :
/// une réponse est donc toujours prête. Un échec réseau devient un
/// non-événement au lieu d'une attente puis d'une erreur.
class RacingQuickAddEngine implements QuickAddEngine {
  RacingQuickAddEngine({
    required this._local,
    required this._remote,
    this.timeout = defaultTimeout,
    this._onRemoteFailure,
    this._onRemoteSuccess,
  });

  /// Au-delà, la saisie traîne. Le filet local est déjà là, on le prend.
  static const Duration defaultTimeout = Duration(seconds: 3);

  final QuickAddEngine _local;
  final QuickAddEngine _remote;
  final Duration timeout;
  final void Function(AiRequestFailure failure)? _onRemoteFailure;
  final void Function()? _onRemoteSuccess;

  @override
  Future<QuickAddClassification> classify(String input) async {
    final localRun = _local.classify(input);
    // Le local peut échouer alors que le distant a déjà gagné : on marque son
    // erreur comme traitée pour ne pas la faire remonter en erreur non gérée.
    localRun.ignore();

    try {
      final classification = await _remote.classify(input).timeout(timeout);
      _onRemoteSuccess?.call();
      return classification;
    } catch (error) {
      _onRemoteFailure?.call(AiRequestFailure.from(error));
      return localRun;
    }
  }
}
