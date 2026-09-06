import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';

class RevenuesSummaryCard extends StatelessWidget {
  final double monthlyRevenues;
  final int transactionCount;

  const RevenuesSummaryCard({
    required this.monthlyRevenues,
    required this.transactionCount,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final finance = context.financeColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FrostedCard(
        radius: FrostedRadius.xl,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'TOTAL ENTRÉES',
                  style: AppTextStyles.mono(
                    fontSize: 10,
                    letterSpacingEm: 0.10,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '$transactionCount transactions',
                  style: AppTextStyles.mono(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '+ ${MoneyFormatter.format(monthlyRevenues)}',
              style: TextStyle(
                fontSize: 32,
                height: 36 / 32,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.022 * 32,
                color: finance.income,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
