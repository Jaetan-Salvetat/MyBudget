import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/core/theme/theme_viewmodel.dart';
import 'package:mybudget/ui/settings/widgets/settings_section.dart';
import 'package:mybudget/ui/settings/widgets/settings_tile.dart';
import 'package:mybudget/ui/settings/widgets/theme_bottom_sheet.dart';

class AppearanceSection extends StatelessWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final themeVM = Provider.of<ThemeViewModel>(context);

    return SettingsSection(
      title: 'Apparence',
      children: [
        SettingsTile(
          title: 'Thème',
          subtitle: _getThemeNameFromMode(themeVM.themeMode),
          leading: const Icon(Icons.brightness_6),
          onTap: () {
            _showThemeSelectionDialog(context, themeVM.themeMode);
          },
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Couleur principale',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        SizedBox(
          height: 60,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: AppThemeType.values.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final type = AppThemeType.values[index];
              final isSelected = themeVM.themeType == type;
              return _ColorSelectorItem(
                type: type,
                isSelected: isSelected,
                onTap: () => themeVM.setThemeType(type),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
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
        final themeVM = Provider.of<ThemeViewModel>(context, listen: false);
        themeVM.setThemeMode(mode);
      },
    );
  }
}

class _ColorSelectorItem extends StatelessWidget {
  final AppThemeType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorSelectorItem({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isSelected ? 40 : 32,
            height: isSelected ? 40 : 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  type == AppThemeType.dynamicColor
                      ? const SweepGradient(
                        colors: [
                          Colors.blue,
                          Colors.purple,
                          Colors.red,
                          Colors.orange,
                          Colors.yellow,
                          Colors.green,
                          Colors.blue,
                        ],
                      )
                      : null,
              color: type == AppThemeType.dynamicColor ? null : type.seedColor,
              border:
                  isSelected
                      ? Border.all(
                        color:
                            type == AppThemeType.dynamicColor
                                ? Theme.of(context).colorScheme.primary
                                : type.seedColor,
                        width: 2,
                      )
                      : Border.all(color: Colors.transparent, width: 0),
            ),
            child: Padding(
              padding: EdgeInsets.all(isSelected ? 3.0 : 0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient:
                      type == AppThemeType.dynamicColor
                          ? const SweepGradient(
                            colors: [
                              Colors.blue,
                              Colors.purple,
                              Colors.red,
                              Colors.orange,
                              Colors.yellow,
                              Colors.green,
                              Colors.blue,
                            ],
                          )
                          : null,
                  color:
                      type == AppThemeType.dynamicColor ? null : type.seedColor,
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: (type == AppThemeType.dynamicColor
                                      ? Theme.of(context).colorScheme.primary
                                      : type.seedColor)
                                  .withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                          : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
