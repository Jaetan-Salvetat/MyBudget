import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/ui/settings/update_provider.dart';
import 'package:mybudget/ui/settings/screens/update_screen.dart';
import 'package:mybudget/ui/settings/widgets/settings_section.dart';
import 'package:mybudget/ui/settings/widgets/settings_tile.dart';
import 'package:mybudget/ui/splash/splash_screen.dart';

class DebugSection extends ConsumerWidget {
  const DebugSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsSection(
      title: 'Debug',
      children: [
        SettingsTile(
          title: 'Réinitialiser l\'Onboarding',
          subtitle: 'Relancer le tutoriel au prochain démarrage',
          leading: const Icon(Icons.restart_alt),
          onTap: () async {
            await PreferencesService.clearAll();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const SplashScreen()),
                (route) => false,
              );
            }
          },
        ),
        if (kDebugMode)
          SettingsTile(
            title: 'Tester la page Update',
            subtitle: 'Fetch la dernière release et ouvre la page',
            leading: const Icon(Icons.bug_report),
            onTap: () async {
              await ref.read(updateProvider.notifier).checkForUpdates();
              if (context.mounted) {
                final state = ref.read(updateProvider);
                if (state.error != null) {
                  FrostedSnackbar.show(context, message: state.error!);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UpdateScreen()),
                  );
                }
              }
            },
          ),
      ],
    );
  }
}
