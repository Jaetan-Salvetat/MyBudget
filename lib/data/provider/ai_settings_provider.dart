import 'package:mybudget/core/enums/ai_model.dart';
import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/data/service/preferences_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ai_settings_provider.g.dart';

@Riverpod(keepAlive: true)
class QuickAddEnabledNotifier extends _$QuickAddEnabledNotifier {
  @override
  bool build() => PreferencesService.isQuickAddEnabled();

  Future<void> setEnabled(bool enabled) async {
    await PreferencesService.setQuickAddEnabled(enabled);
    state = enabled;
  }
}

@Riverpod(keepAlive: true)
class QuickAddEngineModeNotifier extends _$QuickAddEngineModeNotifier {
  @override
  QuickAddEngineMode build() => PreferencesService.getQuickAddEngineMode();

  Future<void> setMode(QuickAddEngineMode mode) async {
    await PreferencesService.setQuickAddEngineMode(mode);
    state = mode;
  }
}

@Riverpod(keepAlive: true)
class SelectedAiProviderNotifier extends _$SelectedAiProviderNotifier {
  @override
  AiProvider build() => PreferencesService.getAiProvider();

  Future<void> select(AiProvider provider) async {
    await PreferencesService.setAiProvider(provider);
    state = provider;
  }
}

@Riverpod(keepAlive: true)
class SelectedAiModelNotifier extends _$SelectedAiModelNotifier {
  @override
  AiModel build() => PreferencesService.getAiModel();

  Future<void> select(AiModel model) async {
    await PreferencesService.setAiModel(model);
    state = model;
  }
}

@Riverpod(keepAlive: true)
Future<bool> hasStoredApiKey(Ref ref) {
  final provider = ref.watch(selectedAiProviderProvider);
  return ref.watch(apiKeyServiceProvider).has(provider);
}

@Riverpod(keepAlive: true)
bool quickAddUsesRemote(Ref ref) {
  if (ref.watch(quickAddEngineModeProvider) != QuickAddEngineMode.apiKey) {
    return false;
  }
  return ref.watch(hasStoredApiKeyProvider).value ?? false;
}
