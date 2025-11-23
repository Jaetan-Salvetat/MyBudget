import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mybudget/ui/settings/update_viewmodel.dart';
import 'package:mybudget/ui/settings/widgets/settings_section.dart';
import 'package:mybudget/ui/settings/widgets/settings_tile.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final updateVM = Provider.of<UpdateViewModel>(context);

    return SettingsSection(
      title: 'À propos',
      children: [
        SettingsTile(
          title: 'Version',
          subtitle: updateVM.currentVersion ?? 'Chargement...',
          leading:
              updateVM.isChecking
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.info_outline),
          onTap: () => updateVM.checkForUpdates(context),
        ),
      ],
    );
  }
}
