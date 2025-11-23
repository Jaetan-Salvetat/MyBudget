import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mybudget/ui/settings/settings_viewmodel.dart';
import 'package:mybudget/ui/settings/widgets/settings_section.dart';
import 'package:mybudget/ui/settings/widgets/settings_tile.dart';
import 'package:mybudget/ui/settings/widgets/theme_bottom_sheet.dart';

class AppearanceSection extends StatelessWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsVM = Provider.of<SettingsViewModel>(context);

    return SettingsSection(
      title: 'Apparence',
      children: [
        SettingsTile(
          title: 'Thème',
          subtitle: _getThemeNameFromMode(settingsVM.themeMode),
          leading: const Icon(Icons.brightness_6),
          onTap: () {
            _showThemeSelectionDialog(context, settingsVM.themeMode);
          },
        ),
      ],
    );
  }

  String _getThemeNameFromMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Automatique';
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
    }
  }

  Future<void> _showThemeSelectionDialog(
    BuildContext context,
    ThemeMode currentMode,
  ) async {
    return ThemeBottomSheet.show(
      context: context,
      currentMode: currentMode,
      onThemeSelected: (ThemeMode mode) {
        final settingsVM = Provider.of<SettingsViewModel>(
          context,
          listen: false,
        );
        settingsVM.updateThemeMode(mode);
      },
    );
  }
}
