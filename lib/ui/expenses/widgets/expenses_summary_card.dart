import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';

class ExpensesSummaryCard extends StatelessWidget {
  final double total;
  final int filteredCount;
  final int totalCount;
  final List<double> weeklyTotals;

  const ExpensesSummaryCard({
    required this.total,
    required this.filteredCount,
    required this.totalCount,
    required this.weeklyTotals,
    super.key,
  });

  bool get _isFiltered => filteredCount != totalCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final finance = context.financeColors;
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

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
                  (_isFiltered ? 'TOTAL FILTRÉ' : 'TOTAL CE MOIS'),
                  style: AppTextStyles.mono(
                    fontSize: 10,
                    letterSpacingEm: 0.10,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  _isFiltered
                      ? '$filteredCount / $totalCount'
                      : '$totalCount transactions',
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
              formatter.format(total),
              style: TextStyle(
                fontSize: 32,
                height: 36 / 32,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.022 * 32,
                color: finance.expense,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 14),
            _WeeklyBars(buckets: weeklyTotals, color: finance.expense),
          ],
        ),
      ),
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  final List<double> buckets;
  final Color color;

  const _WeeklyBars({required this.buckets, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxValue = buckets.isEmpty
        ? 1.0
        : buckets.reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 38,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < buckets.length; i++) ...[
                Expanded(
                  child: Container(
                    height: ((buckets[i] / maxValue) * 32).clamp(3.0, 32.0),
                    decoration: BoxDecoration(
                      color: buckets[i] > 0
                          ? color.withValues(alpha: 0.75)
                          : scheme.onSurface.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                if (i < buckets.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (int i = 0; i < buckets.length; i++) ...[
              Expanded(
                child: Text(
                  'S${i + 1}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.mono(
                    fontSize: 10,
                    letterSpacingEm: 0.04,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (i < buckets.length - 1) const SizedBox(width: 6),
            ],
          ],
        ),
      ],
    );
  }
}
