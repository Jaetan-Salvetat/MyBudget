import 'package:flutter/material.dart';
import 'package:mybudget/ui/settings/widgets/settings_section.dart';
import 'package:mybudget/ui/settings/widgets/settings_tile.dart';
import 'package:mybudget/ui/settings/screens/help_screen.dart';

class HelpSection extends StatelessWidget {
  const HelpSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Aide et informations',
      children: [
        SettingsTile(
          title: 'Guide d\'utilisation',
          subtitle: 'Consultez l\'aide et les explications',
          leading: const Icon(Icons.help_outline),
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              ),
        ),
      ],
    );
  }
}
