import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:mybudget/ui/settings/screens/help_screen.dart';
import 'package:mybudget/ui/settings/screens/labs_screen.dart';

class HelpAndSupportSection extends StatelessWidget {
  const HelpAndSupportSection({super.key});

  static const String labsSubtitle =
      'Activer ou couper les fonctionnalités en cours de mise au point';

  @override
  Widget build(BuildContext context) {
    return FrostedListSection(
      label: 'Aide & Support',
      tiles: [
        FrostedListTile(
          title: 'Guide d\'utilisation',
          subtitle: 'Comment marche chaque écran',
          leading: const FrostedListAvatar(icon: Symbols.help_rounded),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HelpScreen()),
          ),
        ),
        FrostedListTile(
          title: LabsScreen.title,
          subtitle: labsSubtitle,
          leading: const FrostedListAvatar(icon: Symbols.science_rounded),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LabsScreen()),
          ),
        ),
      ],
    );
  }
}
