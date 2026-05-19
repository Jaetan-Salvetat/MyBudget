import 'package:flutter/material.dart';
import 'package:mybudget/ui/common/widgets/eyebrow.dart';

class DashboardGreeting extends StatelessWidget {
  final VoidCallback? onSettingsTap;

  const DashboardGreeting({super.key, this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow('Bonjour'),
                SizedBox(height: 2),
                Text(
                  'Ton mois en clair.',
                  style: TextStyle(
                    fontSize: 22,
                    height: 26 / 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          if (onSettingsTap != null)
            Material(
              color: scheme.onSurface.withValues(alpha: 0.05),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onSettingsTap,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.settings_rounded,
                    size: 20,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
