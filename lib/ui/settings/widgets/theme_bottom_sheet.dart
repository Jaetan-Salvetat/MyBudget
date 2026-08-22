import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:frosted_ui/frosted_ui.dart';

class ThemeBottomSheet extends StatelessWidget {
  final ThemeMode currentMode;
  final Function(ThemeMode) onThemeSelected;

  const ThemeBottomSheet({
    required this.currentMode,
    required this.onThemeSelected,
    super.key,
  });

  static void show({
    required BuildContext context,
    required ThemeMode currentMode,
    required Function(ThemeMode) onThemeSelected,
  }) {
    showFrostedBottomSheet<void>(
      context: context,
      builder: (_) => FrostedBottomSheet(
        title: 'Choisir un thème',
        child: ThemeBottomSheet(
          currentMode: currentMode,
          onThemeSelected: onThemeSelected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildThemeOption(
          context,
          ThemeMode.system,
          'Automatique',
          Symbols.brightness_auto_rounded,
        ),
        const SizedBox(height: 12),
        _buildThemeOption(
          context,
          ThemeMode.light,
          'Clair',
          Symbols.brightness_5_rounded,
        ),
        const SizedBox(height: 12),
        _buildThemeOption(
          context,
          ThemeMode.dark,
          'Sombre',
          Symbols.brightness_2_rounded,
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeMode mode,
    String label,
    IconData icon,
  ) {
    final isSelected = currentMode == mode;

    return FrostedListTile(
      title: label,
      leading: Icon(
        icon,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      trailing: isSelected
          ? Icon(
              Symbols.check_rounded,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () {
        onThemeSelected(mode);
        Navigator.pop(context);
      },
    );
  }
}
