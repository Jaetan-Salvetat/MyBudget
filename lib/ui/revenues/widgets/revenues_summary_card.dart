import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/theme/finance_colors.dart';

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
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return FrostedCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 20,
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
                style: TextStyle(
                  fontSize: 10,
                  height: 14 / 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.10 * 10,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                '$transactionCount transactions',
                style: TextStyle(
                  fontSize: 12,
                  height: 14 / 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '+ ${formatter.format(monthlyRevenues)}',
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
    );
  }
}
