import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
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
    final greeting = _greetingForHour(DateTime.now().hour);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      child: SizedBox(
        height: 48,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
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
              FrostedControlButton(
                icon: Icons.settings_rounded,
                onPressed: onSettingsTap,
              ),
          ],
        ),
      ),
    );
  }
}
