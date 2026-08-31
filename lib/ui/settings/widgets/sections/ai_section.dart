import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:mybudget/core/enums/ai_model.dart';
import 'package:mybudget/core/enums/gemini_nano_status.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';
import 'package:mybudget/ui/settings/screens/ai_model_screen.dart';
import 'package:mybudget/ui/settings/screens/api_key_screen.dart';
import 'package:mybudget/ui/settings/screens/gemini_nano_screen.dart';
import 'package:mybudget/ui/settings/screens/quick_add_engine_screen.dart';

class AiSection extends ConsumerWidget {
  const AiSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool quickAddEnabled = ref.watch(quickAddEnabledProvider);
    final bool hasKey =
        ref.watch(hasStoredApiKeyProvider).value ?? false;
    final QuickAddEngineMode engineMode = ref.watch(quickAddEngineModeProvider);
    final bool usesRemoteEngine = engineMode == QuickAddEngineMode.apiKey;
    final bool usesNano = engineMode == QuickAddEngineMode.geminiNano;
    final AiModel model = ref.watch(selectedAiModelProvider);

    void setEnabled(bool enabled) =>
        ref.read(quickAddEnabledProvider.notifier).setEnabled(enabled);

    return FrostedListSection(
      label: 'Intelligence artificielle',
      tiles: [
        FrostedListTile(
          title: 'Ajout rapide',
          subtitle: _quickAddSubtitle(ref),
          leading: const FrostedListAvatar(icon: Symbols.bolt_rounded),
          trailing: FrostedSwitch(
            value: quickAddEnabled,
            onChanged: setEnabled,
          ),
          onTap: () => setEnabled(!quickAddEnabled),
        ),
        if (quickAddEnabled)
          FrostedListTile(
            title: 'Moteur d\'analyse',
            subtitle: _engineSubtitle(ref),
            leading: const FrostedListAvatar(icon: Symbols.tune_rounded),
            trailing: const Icon(Symbols.chevron_right_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuickAddEngineScreen()),
            ),
          ),
        if (quickAddEnabled && usesNano)
          FrostedListTile(
            title: QuickAddEngineMode.geminiNano.label,
            subtitle: _nanoSubtitle(ref),
            leading: const FrostedListAvatar(
              icon: Symbols.auto_awesome_rounded,
            ),
            trailing: const Icon(Symbols.chevron_right_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GeminiNanoScreen()),
            ),
          ),
        if (quickAddEnabled && usesRemoteEngine) ...[
          FrostedListTile(
            title: 'Clé API',
            subtitle: hasKey ? 'Enregistrée' : 'Aucune clé enregistrée',
            leading: const FrostedListAvatar(icon: Symbols.key_rounded),
            trailing: const Icon(Symbols.chevron_right_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ApiKeyScreen()),
            ),
          ),
          FrostedListTile(
            title: 'Modèle',
            subtitle: model.label,
            leading: const FrostedListAvatar(
              icon: Symbols.auto_awesome_rounded,
            ),
            trailing: const Icon(Symbols.chevron_right_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiModelScreen()),
            ),
          ),
        ],
      ],
    );
  }

  String _quickAddSubtitle(WidgetRef ref) {
    final bool isLocal =
        ref.watch(quickAddEngineModeProvider) != QuickAddEngineMode.apiKey;
    return isLocal
        ? 'Analyse une saisie en langage naturel, sur l\'appareil'
        : 'Analyse une saisie en langage naturel';
  }

  String _nanoSubtitle(WidgetRef ref) {
    return switch (ref.watch(geminiNanoStatusProvider).value) {
      GeminiNanoStatus.available => 'Modèle installé',
      GeminiNanoStatus.downloading => 'Téléchargement en cours',
      GeminiNanoStatus.downloadable => 'Modèle à télécharger',
      _ => 'Indisponible sur cet appareil',
    };
  }

  String _engineSubtitle(WidgetRef ref) {
    final QuickAddEngineMode mode = ref.watch(quickAddEngineModeProvider);
    if (mode != QuickAddEngineMode.apiKey) return mode.label;

    return ref.watch(quickAddDegradationProvider)
        ? 'Sur l\'appareil (secours)'
        : QuickAddEngineMode.apiKey.label;
  }
}
