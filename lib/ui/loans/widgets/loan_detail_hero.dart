import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/entities/loan.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/models/loan_model.dart';

class LoanDetailHero extends StatelessWidget {
  final Loan loan;

  const LoanDetailHero({required this.loan, super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final compactFormatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 0,
    );

    final progress = loan.progressPercentage.clamp(0.0, 1.0);
    final progressPct = (progress * 100).round();
    final amortized = loan.amount - loan.remainingCapital;
    final status = loan.getStatus();
    final statusColor = _statusColor(scheme, status);

    return FrostedCard(
      margin: const EdgeInsets.only(bottom: 14),
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.name,
                      style: TextStyle(
                        fontSize: 18,
                        height: 22 / 18,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      loan.lenderName,
                      style: TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  status.label.toUpperCase(),
                  style: AppTextStyles.mono(
                    fontSize: 11,
                    letterSpacingEm: 0.05,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'MENSUALITÉ COURANTE',
            style: AppTextStyles.mono(
              fontSize: 10,
              letterSpacingEm: 0.10,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatter.format(loan.currentMonthlyPayment),
            style: TextStyle(
              fontSize: 36,
              height: 40 / 36,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.022 * 36,
              color: scheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 16),
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
              value: progress,
              minHeight: 6,
              backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${compactFormatter.format(amortized)} remboursés',
                style: AppTextStyles.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                'sur ${compactFormatter.format(loan.amount)}',
                style: AppTextStyles.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(ColorScheme scheme, LoanStatus status) {
    return switch (status) {
      LoanStatus.pending => scheme.tertiary,
      LoanStatus.partiallyPaid => scheme.primary,
      LoanStatus.completed => scheme.secondary,
    };
  }
}
