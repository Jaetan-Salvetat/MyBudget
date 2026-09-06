import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/ui/splash/splash_screen.dart';

class DebugSection extends StatelessWidget {
  const DebugSection({super.key});

  @override
  Widget build(BuildContext context) {
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
      ],
    );
  }

  Future<void> _restartOnboarding(BuildContext context) async {
    await PreferencesService.clearAll();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }
}
