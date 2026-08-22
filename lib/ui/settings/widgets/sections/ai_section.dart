import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:mybudget/ui/settings/ai_settings_provider.dart';

class AiSection extends ConsumerWidget {
  const AiSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickAddEnabled = ref.watch(quickAddEnabledProvider);
    void setEnabled(bool enabled) =>
        ref.read(quickAddEnabledProvider.notifier).setEnabled(enabled);

    return FrostedListSection(
      label: 'Intelligence artificielle',
      tiles: [
        FrostedListTile(
          title: 'Ajout rapide',
          subtitle: 'Analyse une saisie en langage naturel, sur l\'appareil',
          leading: const FrostedListAvatar(icon: Symbols.bolt_rounded),
          trailing: FrostedSwitch(
            value: quickAddEnabled,
            onChanged: setEnabled,
          ),
          onTap: () => setEnabled(!quickAddEnabled),
        ),
      ],
    );
  }
}
