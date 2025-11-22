import 'package:flutter/material.dart';

class ThemeBottomSheet extends StatelessWidget {
  final ThemeMode currentMode;
  final Function(ThemeMode) onThemeSelected;

  const ThemeBottomSheet({
    required this.currentMode,
    required this.onThemeSelected,
    super.key,
  });

  static Future<void> show({
    required BuildContext context,
    required ThemeMode currentMode,
    required Function(ThemeMode) onThemeSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => ThemeBottomSheet(
            currentMode: currentMode,
            onThemeSelected: onThemeSelected,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choisir un thème',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
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
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeMode mode,
    String label,
    IconData icon,
  ) {
    final isSelected = currentMode == mode;

    return InkWell(
      onTap: () {
        onThemeSelected(mode);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
