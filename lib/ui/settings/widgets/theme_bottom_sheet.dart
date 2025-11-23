import 'package:flutter/material.dart';
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
    FrostedBottomSheet.show(
      context: context,
      title: 'Choisir un thème',
      child: ThemeBottomSheet(
        currentMode: currentMode,
        onThemeSelected: onThemeSelected,
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
          Icons.brightness_auto,
        ),
        const SizedBox(height: 12),
        _buildThemeOption(
          context,
          ThemeMode.light,
          'Clair',
          Icons.brightness_5,
        ),
        const SizedBox(height: 12),
        _buildThemeOption(
          context,
          ThemeMode.dark,
          'Sombre',
          Icons.brightness_2,
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
      onTap: () {
        onThemeSelected(mode);
        Navigator.pop(context);
      },
      leading: Icon(
        icon,
        color:
            isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing:
          isSelected
              ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
              : null,
    );
  }
}
