import 'package:flutter/foundation.dart';

import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/ai/ai_chat_client.dart';
import 'package:mybudget/core/services/ai/gemini_nano_chat_client.dart';
import 'package:mybudget/core/services/quick_add/gemini_nano_unavailable_engine.dart';
import 'package:mybudget/core/services/quick_add/prompt_quick_add_engine.dart';
import 'package:mybudget/core/services/quick_add/quick_add_engine.dart';
import 'package:mybudget/core/services/quick_add/racing_quick_add_engine.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_add_engine_provider.g.dart';

@Riverpod(keepAlive: true)
Future<QuickAddEngine> quickAddEngine(Ref ref) async {
  final mode = ref.watch(quickAddEngineModeProvider);

  if (mode == QuickAddEngineMode.geminiNano) {
    final status = await ref.watch(geminiNanoStatusProvider.future);
    if (!status.isReady) return GeminiNanoUnavailableEngine.forStatus(status);

    return PromptQuickAddEngine(
      client: const GeminiNanoChatClient(),
      taxonomy: await ref.watch(categoryTaxonomyProvider.future),
    );
  }

  final local = await ref.watch(quickAddClassifierProvider.future);

  if (mode != QuickAddEngineMode.apiKey) return local;

  if (ref.watch(quickAddDegradationProvider)) return local;

  final provider = ref.watch(selectedAiProviderProvider);
  final model = ref.watch(selectedAiModelProvider);

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
    remote: PromptQuickAddEngine(
      client: client,
      taxonomy: await ref.watch(categoryTaxonomyProvider.future),
    ),
    onRemoteFailure: degradation.reportFailure,
    onRemoteSuccess: degradation.reportSuccess,
  );
}

@Riverpod(keepAlive: true)
Future<void> quickAddWarmUp(Ref ref) async {
  if (!ref.read(quickAddEnabledProvider)) return;

  try {
    await ref.read(quickAddEngineProvider.future);
    if (ref.read(quickAddEngineModeProvider) == QuickAddEngineMode.geminiNano) {
      await ref.read(geminiNanoServiceProvider).warmUp();
    }
  } catch (error, stackTrace) {
    debugPrint(
      'Prechargement de l\'ajout rapide impossible : '
      '$error\n$stackTrace',
    );
  }
}
