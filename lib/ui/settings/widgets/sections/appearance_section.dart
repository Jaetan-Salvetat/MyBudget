import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mybudget/core/theme/theme_provider.dart';
import 'package:mybudget/ui/settings/widgets/settings_section.dart';
import 'package:mybudget/ui/settings/widgets/settings_tile.dart';
import 'package:mybudget/ui/settings/widgets/theme_bottom_sheet.dart';

class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return SettingsSection(
      title: 'Apparence',
      children: [
        SettingsTile(
          title: 'Thème',
          subtitle: _getThemeNameFromMode(themeState.themeMode),
          leading: const Icon(Icons.brightness_6),
          onTap: () => _showThemeSelectionDialog(context, ref, themeState.themeMode),
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
    WidgetRef ref,
    ThemeMode currentMode,
  ) async {
    return ThemeBottomSheet.show(
      context: context,
      currentMode: currentMode,
      onThemeSelected: (ThemeMode mode) {
        ref.read(themeProvider.notifier).setThemeMode(mode);
      },
    );
  }
}
