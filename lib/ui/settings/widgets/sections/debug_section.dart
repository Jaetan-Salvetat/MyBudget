import 'package:flutter/material.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/ui/settings/widgets/settings_section.dart';
import 'package:mybudget/ui/settings/widgets/settings_tile.dart';
import 'package:mybudget/ui/splash/splash_screen.dart';

class DebugSection extends StatelessWidget {
  const DebugSection({super.key});

  @override
  Widget build(BuildContext context) {
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
      ],
    );
  }
}
