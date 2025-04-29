import 'package:flutter/material.dart';
import 'package:mybudget/presentation/widgets/common/modal_bottom_sheet.dart';

class ThemeBottomSheet {
  static Future<void> show({
    required BuildContext context,
    required ThemeMode currentMode,
    required Function(ThemeMode) onThemeSelected,
  }) {
    return AppModalBottomSheet.show(
      context: context,
      title: 'Choisir un thème',
      content: _ThemeSelectionContent(
        currentMode: currentMode,
        onThemeSelected: onThemeSelected,
      ),
      actions: const [],
    );
  }
}

class _ThemeSelectionContent extends StatelessWidget {
  final ThemeMode currentMode;
  final Function(ThemeMode) onThemeSelected;

  const _ThemeSelectionContent({
    required this.currentMode,
    required this.onThemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildThemeOption(
          context,
          title: 'Automatique',
          subtitle: 'Suit le thème du système',
          icon: Icons.brightness_auto,
          isSelected: currentMode == ThemeMode.system,
          onTap: () {
            onThemeSelected(ThemeMode.system);
            Navigator.of(context).pop();
          },
        ),
        const SizedBox(height: 12),
        _buildThemeOption(
          context,
          title: 'Clair',
          subtitle: 'Thème lumineux',
          icon: Icons.wb_sunny,
          isSelected: currentMode == ThemeMode.light,
          onTap: () {
            onThemeSelected(ThemeMode.light);
            Navigator.of(context).pop();
          },
        ),
        const SizedBox(height: 12),
        _buildThemeOption(
          context,
          title: 'Sombre',
          subtitle: 'Thème foncé',
          icon: Icons.nights_stay,
          isSelected: currentMode == ThemeMode.dark,
          onTap: () {
            onThemeSelected(ThemeMode.dark);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
