import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';
import 'package:mybudget/ui/settings/screens/api_key_screen.dart';
import 'package:mybudget/ui/settings/screens/quick_add_engine_screen.dart';

class AiSection extends ConsumerWidget {
  const AiSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool quickAddEnabled = ref.watch(quickAddEnabledProvider);
    final bool hasKey =
        ref.watch(hasStoredApiKeyProvider).value ?? false;

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
        // Rien n'annonce la clé : la tuile n'apparaît qu'une fois qu'il y en a
        // une, pour la revoir ou la supprimer. On y arrive par le moteur
        // d'analyse ou par le scan de ticket, là où elle sert.
        if (hasKey)
          FrostedListTile(
            title: 'Clé API',
            subtitle: 'Enregistrée',
            leading: const FrostedListAvatar(icon: Symbols.key_rounded),
            trailing: const Icon(Symbols.chevron_right_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ApiKeyScreen()),
            ),
          ),
      ],
    );
  }

  /// La mention « sur l'appareil » disparaît dès que ce n'est plus vrai.
  String _quickAddSubtitle(WidgetRef ref) {
    final bool isLocal =
        ref.watch(quickAddEngineModeProvider) ==
        QuickAddEngineMode.onDevice;
    return isLocal
        ? 'Analyse une saisie en langage naturel, sur l\'appareil'
        : 'Analyse une saisie en langage naturel';
  }

  String _engineSubtitle(WidgetRef ref) {
    if (ref.watch(quickAddEngineModeProvider) ==
        QuickAddEngineMode.onDevice) {
      return QuickAddEngineMode.onDevice.label;
    }
    return ref.watch(quickAddDegradationProvider)
        ? 'Sur l\'appareil (secours)'
        : QuickAddEngineMode.apiKey.label;
  }
}
