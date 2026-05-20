import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';

class LoanSummaryCard extends StatelessWidget {
  final double totalDebt;
  final double monthlyPayment;
  final double progress;
  final int activeLoanCount;
  final double remainingCost;

  const LoanSummaryCard({
    required this.totalDebt,
    required this.monthlyPayment,
    required this.progress,
    required this.activeLoanCount,
    required this.remainingCost,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final compactFormatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 0,
    );
    final progressPct = (progress * 100).clamp(0, 100).round();

    return FrostedCard(
      margin: const EdgeInsets.only(bottom: 14),
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MENSUALITÉS DU MOIS',
            style: TextStyle(
              fontSize: 10,
              height: 14 / 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.10 * 10,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatter.format(monthlyPayment),
                style: TextStyle(
                  fontSize: 32,
                  height: 36 / 32,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.022 * 32,
                  color: scheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '· $activeLoanCount actif${activeLoanCount > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 13,
                  height: 16 / 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Capital amorti',
                style: TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                '$progressPct%',
                style: TextStyle(
                  fontSize: 14,
                  height: 18 / 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: FrostedLinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  width: 0.5,
                  color: scheme.onSurface.withValues(alpha: 0.07),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'Capital restant',
                    value: compactFormatter.format(totalDebt),
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: 'Coût restant',
                    value: compactFormatter.format(remainingCost),
                    hint: 'Intérêts + assurance',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;

  const _Stat({required this.label, required this.value, this.hint});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            height: 14 / 11,
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            height: 20 / 16,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(
            hint!,
            style: TextStyle(
              fontSize: 10,
              height: 14 / 10,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}
