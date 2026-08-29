import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/common/widgets/animated_amount.dart';
import 'package:mybudget/ui/common/widgets/eyebrow.dart';

/// What the month has left, counting down under the eye at every send. It is
/// the only figure on the capture screen : a tap hands the rest over to Stats.
class CaptureAnchor extends StatelessWidget {
  static const double integerFontSize = 52;
  static const double centsFontSize = 30;
  static const double _centsOpacity = 0.62;

  final double remaining;
  final double monthlyRevenues;
  final VoidCallback onTap;

  const CaptureAnchor({
    required this.remaining,
    required this.monthlyRevenues,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FrostedRadius.lg),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          FrostedSpacing.sp1,
          FrostedSpacing.sp5,
          FrostedSpacing.sp1,
          FrostedSpacing.sp5,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Eyebrow('Reste ce mois'),
                  const SizedBox(height: FrostedSpacing.sp2),
                  AnimatedAmount(
                    amount: remaining,
                    builder: (context, value) => _Figure(amount: value),
                  ),
                  const SizedBox(height: FrostedSpacing.sp2),
                  Text(
                    _subtitle(),
                    style: AppTextStyles.mono(
                      fontSize: 10.5,
                      lineHeight: 14,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Symbols.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle() {
    final now = DateTime.now();
    final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day + 1;
    final revenues = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
    ).format(monthlyRevenues);
    final days = daysLeft > 1 ? '$daysLeft jours' : '$daysLeft jour';

    return 'sur $revenues de revenus · $days';
  }
}

class _Figure extends StatelessWidget {
  final double amount;

  const _Figure({required this.amount});

  @override
  Widget build(BuildContext context) {
    final color = amount < 0
        ? context.financeColors.expense
        : Theme.of(context).colorScheme.onSurface;
    final formatted = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
    ).format(amount);
    final split = formatted.indexOf(',');
    final units = split == -1 ? formatted : formatted.substring(0, split);
    final cents = split == -1 ? '' : formatted.substring(split);

    return Text.rich(
      TextSpan(
        text: units,
        style: AppTextStyles.displaySerifItalic(
          fontSize: CaptureAnchor.integerFontSize,
          height: 1,
          color: color,
        ),
        children: [
          if (cents.isNotEmpty)
            TextSpan(
              text: cents,
              style: AppTextStyles.displaySerifItalic(
                fontSize: CaptureAnchor.centsFontSize,
                height: 1,
                color: color.withValues(alpha: CaptureAnchor._centsOpacity),
              ),
            ),
        ],
      ),
      maxLines: 1,
    );
  }
}
