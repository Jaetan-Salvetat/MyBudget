import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/models/loan_model.dart';

class LoanProgressSection extends StatelessWidget {
  final LoanModel loan;
  final NumberFormat formatter;

  const LoanProgressSection({
    required this.loan,
    required this.formatter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final paidAmount = loan.getAutomaticPaidAmount();
    final progress = loan.amount == 0 ? 0.0 : paidAmount / loan.amount;
    final remainingAmount = loan.amount - paidAmount;
    final progressText = '${(progress * 100).toInt()}%';

    return FrostedCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progression du remboursement',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              LinearProgressIndicator(
                value: progress,
                minHeight: 24,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              Text(
                progressText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      progress > 0.5
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payé: ${formatter.format(paidAmount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                'Reste: ${formatter.format(remainingAmount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total: ${formatter.format(loan.amount)}',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
