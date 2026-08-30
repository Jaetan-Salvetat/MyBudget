import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/constants/layout_insets.dart';
import 'package:mybudget/ui/common/widgets/eyebrow.dart';

class StatsGreeting extends StatelessWidget {
  final VoidCallback? onSettingsTap;

  const StatsGreeting({super.key, this.onSettingsTap});

  String _greetingForHour(int hour) {
    if (hour >= 5 && hour < 12) return 'Bonjour';
    if (hour >= 12 && hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _greetingForHour(DateTime.now().hour);

    return Padding(
      padding: kMainFlowTopBarPadding,
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
              FrostedIconButton.tonal(
                icon: Symbols.settings_rounded,
                onPressed: onSettingsTap,
              ),
          ],
        ),
      ),
    );
  }
}
