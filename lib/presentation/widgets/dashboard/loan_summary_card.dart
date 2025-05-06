import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/data/models/loan_model.dart';

class LoanSummaryCard extends StatelessWidget {
  final List<LoanModel> loans;
  final NumberFormat formatter;

  const LoanSummaryCard({
    required this.loans,
    required this.formatter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final totalRemaining = _calculateTotalRemaining();
    final monthlyPayments = _calculateMonthlyPayments();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Résumé des emprunts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reste à payer',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        formatter.format(totalRemaining),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mensualités',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        formatter.format(monthlyPayments),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (loans.isNotEmpty) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _calculateOverallProgress(),
                borderRadius: BorderRadius.circular(12),
                minHeight: 6,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progression',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    '${(_calculateOverallProgress() * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _calculateTotalRemaining() {
    if (loans.isEmpty) return 0.0;
    return loans.fold(
      0.0,
      (sum, loan) => sum + (loan.amount - loan.getAutomaticPaidAmount()),
    );
  }

  double _calculateMonthlyPayments() {
    if (loans.isEmpty) return 0.0;
    return loans.fold(
      0.0,
      (sum, loan) => sum + (loan.isCompleted() ? 0 : loan.monthlyPayment),
    );
  }

  double _calculateOverallProgress() {
    if (loans.isEmpty) return 0.0;

    final totalAmount = loans.fold(0.0, (sum, loan) => sum + loan.amount);
    final totalPaid = loans.fold(
      0.0,
      (sum, loan) => sum + loan.getAutomaticPaidAmount(),
    );

    if (totalAmount == 0) return 0.0;
    return totalPaid / totalAmount;
  }
}
