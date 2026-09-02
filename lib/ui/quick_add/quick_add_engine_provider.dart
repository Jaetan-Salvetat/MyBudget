import 'package:flutter/foundation.dart';

import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/core/exceptions/quick_add_exception.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/ai/ai_chat_client.dart';
import 'package:mybudget/core/services/quick_add/cloud_quick_add_prompt.dart';
import 'package:mybudget/core/services/quick_add/prompt_quick_add_engine.dart';
import 'package:mybudget/core/services/quick_add/quick_add_engine.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_add_engine_provider.g.dart';

@Riverpod(keepAlive: true)
Future<QuickAddEngine> quickAddEngine(Ref ref) async {
  if (ref.watch(quickAddEngineModeProvider) != QuickAddEngineMode.apiKey) {
    return ref.watch(quickAddClassifierProvider.future);
  }

  final provider = ref.watch(selectedAiProviderProvider);

  final String? apiKey;
  try {
    apiKey = await ref.watch(apiKeyServiceProvider).read(provider);
  } catch (error, stackTrace) {
    debugPrint('Lecture de la clé API impossible : $error\n$stackTrace');
    throw const QuickAddEngineUnavailableException(
      message: 'Clé API illisible, ouvre les réglages pour la ressaisir',
    );
  }
  if (apiKey == null) {
    throw const QuickAddEngineUnavailableException(
      message: 'Aucune clé API enregistrée, ouvre les réglages',
    );
  }

  final client = OpenAiCompatibleChatClient(
    provider: provider,
    model: ref.watch(selectedAiModelProvider),
    apiKey: apiKey,
  );
  ref.onDispose(client.close);

  final taxonomy = await ref.watch(categoryTaxonomyProvider.future);

  return PromptQuickAddEngine(
    client: client,
    taxonomy: taxonomy,
    prompt: CloudQuickAddPrompt(taxonomy.selectableLeaves),
  );
}

@Riverpod(keepAlive: true)
Future<void> quickAddWarmUp(Ref ref) async {
  if (!ref.read(quickAddEnabledProvider)) return;

  try {
    await ref.read(quickAddEngineProvider.future);
  } catch (error, stackTrace) {
    debugPrint(
      'Prechargement de l\'ajout rapide impossible : '
      '$error\n$stackTrace',
    );
  }
}
