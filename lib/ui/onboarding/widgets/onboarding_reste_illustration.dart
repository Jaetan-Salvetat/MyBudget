import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/common/widgets/eyebrow.dart';
import 'package:mybudget/ui/onboarding/widgets/onboarding_svgs.dart';

class OnboardingResteIllustration extends StatelessWidget {
  const OnboardingResteIllustration({super.key});

  String _hex(Color color) {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }

  String _rgba(Color color, double opacity) {
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    return 'rgba($r,$g,$b,$opacity)';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final finance = context.financeColors;

    final svg = OnboardingSvgs.reste
        .replaceAll('{{primary}}', _hex(scheme.primary))
        .replaceAll('{{secondary}}', _hex(scheme.secondary))
        .replaceAll('{{income}}', _hex(finance.income))
        .replaceAll('{{onSurface08}}', _rgba(scheme.onSurface, 0.08));

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.string(svg),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Eyebrow('Reste à vivre'),
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.displaySerifItalic(
                    fontSize: 56,
                    height: 60 / 56,
                    color: scheme.onSurface,
                  ),
                  children: [
                    const TextSpan(text: '847'),
                    TextSpan(
                      text: ',30€',
                      style: AppTextStyles.displaySerifItalic(
                        fontSize: 56,
                        height: 60 / 56,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "+ 31 jours d'avance",
                style: AppTextStyles.mono(
                  fontSize: 12,
                  lineHeight: 16,
                  color: finance.income,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
