import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/ui/settings/update_provider.dart';
import 'package:mybudget/ui/settings/widgets/settings_section.dart';
import 'package:mybudget/ui/settings/widgets/settings_tile.dart';

class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(updateProvider);

    return SettingsSection(
      title: 'À propos',
      children: [
        SettingsTile(
          title: 'Version',
          subtitle: updateState.currentVersion ?? 'Chargement...',
          leading:
              updateState.isChecking
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.info_outline),
          onTap: () => ref.read(updateProvider.notifier).checkForUpdates(context),
        ),
      ],
    );
  }
}
