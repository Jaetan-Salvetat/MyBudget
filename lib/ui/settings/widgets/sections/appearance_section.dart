import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:mybudget/core/theme/theme_provider.dart';
import 'package:mybudget/ui/settings/widgets/theme_bottom_sheet.dart';

class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return FrostedListSection(
      label: 'Apparence',
      tiles: [
        FrostedListTile(
          title: 'Thème',
          subtitle: _themeName(themeState.themeMode),
          leading: const FrostedListAvatar(icon: Symbols.brightness_6_rounded),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => _selectTheme(context, ref, themeState.themeMode),
        ),
      ],
    );
  }

  String _themeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Automatique';
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
    }
  }

  void _selectTheme(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
  ) {
    ThemeBottomSheet.show(
      context: context,
      currentMode: currentMode,
      onThemeSelected: (ThemeMode mode) {
        ref.read(themeProvider.notifier).setThemeMode(mode);
      },
    );
  }
}
