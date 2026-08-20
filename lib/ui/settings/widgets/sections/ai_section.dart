import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';
import 'package:mybudget/ui/settings/widgets/settings_section.dart';
import 'package:mybudget/ui/settings/widgets/settings_switch_tile.dart';

class AiSection extends ConsumerWidget {
  const AiSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickAddEnabled = ref.watch(quickAddEnabledProvider);

    return SettingsSection(
      title: 'Intelligence artificielle',
      children: [
        SettingsSwitchTile(
          title: 'Ajout rapide',
          subtitle:
              'Analyse une saisie en langage naturel, hors ligne et sur '
              'l\'appareil',
          leading: const Icon(Symbols.bolt_rounded),
          value: quickAddEnabled,
          onChanged: (enabled) => ref
              .read(quickAddEnabledProvider.notifier)
              .setEnabled(enabled),
        ),
      ],
    );
  }
}
