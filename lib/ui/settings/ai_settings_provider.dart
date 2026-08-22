import 'package:mybudget/core/enums/ai_model.dart';
import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/core/enums/ai_request_failure.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/preferences_service.dart';
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

/// Le moteur retenu. Il ne bascule sur [QuickAddEngineMode.apiKey] qu'après une
/// vérification aboutie : cocher l'option ne suffit pas.
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

/// Le modèle interrogé avec la clé de l'utilisateur. Le changer ne touche ni
/// la clé ni le moteur : seul l'identifiant envoyé au service change.
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
class AiCloudConsentNotifier extends _$AiCloudConsentNotifier {
  @override
  bool build() => PreferencesService.hasAcceptedAiCloudConsent();

  Future<void> accept() async {
    await PreferencesService.setAiCloudConsent(true);
    state = true;
  }
}

/// Vrai quand la clé du fournisseur courant est dans le trousseau. La clé
/// elle-même ne remonte jamais jusqu'à l'UI.
@Riverpod(keepAlive: true)
Future<bool> hasStoredApiKey(Ref ref) {
  final provider = ref.watch(selectedAiProviderProvider);
  return ref.watch(apiKeyServiceProvider).has(provider);
}

/// Vrai quand une saisie part réellement sur le réseau. C'est ce que la barre
/// d'ajout rapide montre, discrètement : l'utilisateur doit pouvoir le voir
/// sans avoir à ouvrir les réglages.
@Riverpod(keepAlive: true)
bool quickAddUsesRemote(Ref ref) {
  if (ref.watch(quickAddEngineModeProvider) != QuickAddEngineMode.apiKey) {
    return false;
  }
  if (ref.watch(quickAddDegradationProvider)) return false;
  return ref.watch(hasStoredApiKeyProvider).value ?? false;
}

/// L'ajout rapide est-il retombé en local malgré une clé active. Ne passe à
/// vrai qu'une fois : l'utilisateur est prévenu une seule fois.
@Riverpod(keepAlive: true)
class QuickAddDegradationNotifier extends _$QuickAddDegradationNotifier {
  @override
  bool build() => ref.watch(quickAddEngineHealthProvider).isDegraded;

  Future<void> reportFailure(AiRequestFailure failure) async {
    final justDegraded = await ref
        .read(quickAddEngineHealthProvider)
        .recordFailure(failure);
    if (justDegraded) state = true;
  }

  Future<void> reportSuccess() async {
    await ref.read(quickAddEngineHealthProvider).recordSuccess();
    if (state) state = false;
  }

  Future<void> clear() async {
    await ref.read(quickAddEngineHealthProvider).reset();
    state = false;
  }
}
