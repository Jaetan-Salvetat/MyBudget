import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:mybudget/ui/settings/screens/help_screen.dart';

class HelpAndSupportSection extends StatelessWidget {
  const HelpAndSupportSection({super.key});

  @override
  Widget build(BuildContext context) {
    return FrostedListSection(
      label: 'Aide & Support',
      tiles: [
        FrostedListTile(
          title: 'Guide d\'utilisation',
          subtitle: 'Consultez l\'aide et les explications',
          leading: const FrostedListAvatar(icon: Symbols.help_rounded),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HelpScreen()),
          ),
        ),
      ],
    );
  }
}
