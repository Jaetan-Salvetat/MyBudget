import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_input_bar.dart';
import 'package:mybudget/ui/settings/settings_screen.dart';

class QuickAddNoModelCard extends StatelessWidget {
  final VoidCallback onDismiss;

  const QuickAddNoModelCard({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FrostedContainer(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      borderRadius: BorderRadius.circular(22),
      blurStrength: kQuickAddBlur,
      backgroundColor: scheme.primary.withValues(alpha: 0.12),
      borderColor: scheme.primary.withValues(alpha: 0.24),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Symbols.download_rounded,
              size: 20,
              color: scheme.primary,
              fill: 1,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Modèle IA requis',
                  style: TextStyle(
                    fontSize: 14,
                    height: 18 / 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Téléchargez un modèle dans les paramètres',
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FrostedFilledButton(
            onPressed: () {
              onDismiss();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: const Text(
              'Paramètres',
              style: TextStyle(
                fontSize: 13,
                height: 16 / 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
