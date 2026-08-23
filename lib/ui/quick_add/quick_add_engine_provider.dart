import 'package:flutter/foundation.dart';

import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/ai/ai_chat_client.dart';
import 'package:mybudget/core/services/quick_add/quick_add_engine.dart';
import 'package:mybudget/core/services/quick_add/racing_quick_add_engine.dart';
import 'package:mybudget/core/services/quick_add/remote_quick_add_engine.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_add_engine_provider.g.dart';

/// Compose le moteur effectif. Toute raison de ne pas pouvoir appeler le
/// distant — pas de clé, moteur dégradé, mode local — redonne simplement le
/// moteur embarqué : l'ajout rapide n'a aucun état où il ne marche pas.
@Riverpod(keepAlive: true)
Future<QuickAddEngine> quickAddEngine(Ref ref) async {
  final local = await ref.watch(quickAddClassifierProvider.future);

  if (ref.watch(quickAddEngineModeProvider) !=
      QuickAddEngineMode.apiKey) {
    return local;
  }

  if (ref.watch(quickAddDegradationProvider)) return local;

  final provider = ref.watch(selectedAiProviderProvider);
  final model = ref.watch(selectedAiModelProvider);

  // Un trousseau verrouillé ou indisponible ne doit pas priver l'utilisateur
  // de l'ajout rapide : on retombe sur le moteur embarqué.
  final String? apiKey;
  try {
    apiKey = await ref.watch(apiKeyServiceProvider).read(provider);
  } catch (error, stackTrace) {
    debugPrint('Lecture de la clé API impossible : $error\n$stackTrace');
    return local;
  }
  if (apiKey == null) return local;

  final client = OpenAiCompatibleChatClient(
    provider: provider,
    model: model,
    apiKey: apiKey,
  );
  ref.onDispose(client.close);

  final degradation = ref.read(quickAddDegradationProvider.notifier);

  return RacingQuickAddEngine(
    local: local,
    remote: RemoteQuickAddEngine(
      client: client,
      taxonomy: await ref.watch(categoryTaxonomyProvider.future),
    ),
    onRemoteFailure: degradation.reportFailure,
    onRemoteSuccess: degradation.reportSuccess,
  );
}

/// Le moteur se chargeait au premier caractere tape : le modele et le
/// tokenizer arrivaient pendant que l'utilisateur attendait sa categorie.
/// Le declencher au splash sort ce cout du chemin critique — l'ecran dure
/// deja plus longtemps que le chargement.
///
/// Un echec ne remonte pas : l'ajout rapide n'est pas ce qui doit empecher
/// l'app de demarrer, et l'erreur se represente d'elle-meme au premier usage.
@Riverpod(keepAlive: true)
Future<void> quickAddWarmUp(Ref ref) async {
  if (!ref.read(quickAddEnabledProvider)) return;

  try {
    await ref.read(quickAddEngineProvider.future);
  } catch (error, stackTrace) {
    debugPrint('Prechargement de l\'ajout rapide impossible : '
        '$error\n$stackTrace');
  }
}
