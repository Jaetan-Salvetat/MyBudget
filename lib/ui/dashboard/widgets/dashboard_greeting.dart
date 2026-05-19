import 'package:flutter/material.dart';
import 'package:mybudget/ui/common/widgets/eyebrow.dart';

class DashboardGreeting extends StatelessWidget {
  final VoidCallback? onSettingsTap;

  const DashboardGreeting({super.key, this.onSettingsTap});

  String _greetingForHour(int hour) {
    if (hour >= 5 && hour < 12) return 'Bonjour';
    if (hour >= 12 && hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final greeting = _greetingForHour(DateTime.now().hour);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(greeting),
                const SizedBox(height: 2),
                const Text(
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
