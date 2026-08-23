import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mybudget/ui/onboarding/widgets/onboarding_svgs.dart';

class OnboardingLockIllustration extends StatelessWidget {
  const OnboardingLockIllustration({super.key});

  String _hex(Color color) {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final svg = OnboardingSvgs.lock
        .replaceAll('{{primary}}', _hex(scheme.primary))
        .replaceAll('{{secondary}}', _hex(scheme.secondary))
        .replaceAll(
          '{{borderBright}}',
          isDark ? 'rgba(255,255,255,0.20)' : 'rgba(255,255,255,0.55)',
        );

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.string(svg),
          Icon(
            Symbols.lock_rounded,
            size: 88,
            color: scheme.primary.withValues(alpha: 0.7),
          ),
          Positioned(
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(
                  width: 0.5,
                  color: scheme.onSurface.withValues(alpha: 0.10),
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Symbols.cloud_off_rounded,
                    size: 16,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '0 connexion · 0 publicité',
                    style: TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
