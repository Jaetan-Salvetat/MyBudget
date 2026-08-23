import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:mybudget/ui/settings/screens/update_screen.dart';
import 'package:mybudget/ui/settings/update_provider.dart';

class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(updateProvider);
    final hasUpdate = updateState.availableUpdate != null;

    return FrostedListSection(
      label: 'À propos',
      tiles: [
        FrostedListTile(
          title: 'Version',
          subtitle: updateState.currentVersion ?? 'Chargement...',
          leading: const FrostedListAvatar(icon: Symbols.info_rounded),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasUpdate) ...[
                const FrostedBadgeView(badge: FrostedBadge.dot()),
                const SizedBox(width: FrostedSpacing.sp2),
              ],
              const Icon(Symbols.chevron_right_rounded),
            ],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UpdateScreen()),
          ),
        ),
      ],
    );
  }
}
