import 'package:app_updater/app_updater.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            subtitle: 'Simule une mise à jour disponible',
            leading: const Icon(Icons.bug_report),
            onTap: () {
              ref.read(updateProvider.notifier).setFakeUpdate(
                ReleaseInfo(
                  version: '99.0.0',
                  tagName: 'v99.0.0',
                  title: 'Version test',
                  notes: '## 🚀 Nouveautés\n- Soyez informé dès qu\'une nouvelle version est disponible et mettez à jour directement depuis l\'application\n- Touchez une catégorie du dashboard pour voir ses dépenses en détail',
                  publishedAt: DateTime.now(),
                  isPrerelease: false,
                  assets: [
                    ReleaseAsset(
                      name: 'app-prod-release.apk',
                      downloadUrl: 'https://example.com/fake.apk',
                      size: 45 * 1024 * 1024,
                      contentType: 'application/vnd.android.package-archive',
                    ),
                  ],
                ),
              );
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpdateScreen()),
              );
            },
          ),
      ],
    );
  }
}
