import 'package:app_updater/app_updater.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/ui/settings/screens/update_screen.dart';
import 'package:mybudget/ui/settings/update_provider.dart';
import 'package:mybudget/ui/splash/splash_screen.dart';

class DebugSection extends ConsumerWidget {
  const DebugSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FrostedListSection(
      label: 'Debug',
      tiles: [
        FrostedListTile(
          title: 'Réinitialiser l\'Onboarding',
          subtitle: 'Relancer le tutoriel au prochain démarrage',
          leading: const FrostedListAvatar(icon: Symbols.restart_alt_rounded),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => _restartOnboarding(context),
        ),
        if (kDebugMode)
          FrostedListTile(
            title: 'Tester la page Update',
            subtitle: 'Simule une mise à jour disponible',
            leading: const FrostedListAvatar(icon: Symbols.bug_report_rounded),
            trailing: const Icon(Symbols.chevron_right_rounded),
            onTap: () => _previewUpdateScreen(context, ref),
          ),
      ],
    );
  }

  Future<void> _restartOnboarding(BuildContext context) async {
    await PreferencesService.clearAll();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  void _previewUpdateScreen(BuildContext context, WidgetRef ref) {
    ref
        .read(updateProvider.notifier)
        .setFakeUpdate(
          ReleaseInfo(
            version: '99.0.0',
            tagName: 'v99.0.0',
            title: 'Version test',
            notes:
                '## 🚀 Nouveautés\n- Soyez informé dès qu\'une nouvelle version est disponible et mettez à jour directement depuis l\'application\n- Touchez une catégorie du dashboard pour voir ses dépenses en détail',
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
  }
}
