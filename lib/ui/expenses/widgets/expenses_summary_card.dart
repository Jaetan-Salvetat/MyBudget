import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/theme/finance_colors.dart';

class ExpensesSummaryCard extends StatelessWidget {
  final double monthlyAmount;
  final double annualAmount;
  final double oneTimeAmount;
  final int transactionCount;

  const ExpensesSummaryCard({
    required this.monthlyAmount,
    required this.annualAmount,
    required this.oneTimeAmount,
    required this.transactionCount,
    super.key,
  });

  double get _total => monthlyAmount + annualAmount + oneTimeAmount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final finance = context.financeColors;
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final compactFormatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 0,
    );

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
              _Eyebrow(text: 'Total ce mois'),
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
            formatter.format(_total),
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
          _SplitBar(
            monthly: monthlyAmount,
            annual: annualAmount,
            oneTime: oneTimeAmount,
            scheme: scheme,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _LegendItem(
                color: scheme.primary,
                label: 'Mensuel',
                amount: compactFormatter.format(monthlyAmount),
              ),
              _LegendItem(
                color: scheme.secondary,
                label: 'Annuel',
                amount: compactFormatter.format(annualAmount),
              ),
              _LegendItem(
                color: scheme.tertiary,
                label: 'Ponct.',
                amount: compactFormatter.format(oneTimeAmount),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SplitBar extends StatelessWidget {
  final double monthly;
  final double annual;
  final double oneTime;
  final ColorScheme scheme;

  const _SplitBar({
    required this.monthly,
    required this.annual,
    required this.oneTime,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final total = monthly + annual + oneTime;
    if (total <= 0) {
      return Container(
        height: 6,
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(9999),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(9999),
      child: SizedBox(
        height: 6,
        child: Row(
          children: [
            if (monthly > 0)
              Expanded(
                flex: (monthly * 1000).round(),
                child: Container(color: scheme.primary),
              ),
            if (annual > 0)
              Expanded(
                flex: (annual * 1000).round(),
                child: Container(color: scheme.secondary),
              ),
            if (oneTime > 0)
              Expanded(
                flex: (oneTime * 1000).round(),
                child: Container(color: scheme.tertiary),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String amount;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label $amount',
          style: TextStyle(
            fontSize: 12,
            height: 16 / 12,
            color: scheme.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _Eyebrow extends StatelessWidget {
  final String text;
  const _Eyebrow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        height: 14 / 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.10 * 10,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
