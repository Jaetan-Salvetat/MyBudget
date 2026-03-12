import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';

class AccountBalanceBreakdown extends StatelessWidget {
  final double totalRevenues;
  final double totalExpenses;
  final double totalLoanPayments;
  final double totalTransfers;
  final double balance;
  final NumberFormat formatter;

  const AccountBalanceBreakdown({
    required this.totalRevenues,
    required this.totalExpenses,
    required this.totalLoanPayments,
    required this.totalTransfers,
    required this.balance,
    required this.formatter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FrostedCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Décomposition du solde',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildLine(
            context,
            sign: '+',
            label: 'Revenus',
            amount: totalRevenues,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          _buildLine(
            context,
            sign: '-',
            label: 'Dépenses',
            amount: totalExpenses,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 8),
          _buildLine(
            context,
            sign: '-',
            label: 'Mensualités',
            amount: totalLoanPayments,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 8),
          _buildLine(
            context,
            sign: totalTransfers >= 0 ? '+' : '-',
            label: 'Virements',
            amount: totalTransfers.abs(),
            color: totalTransfers >= 0
                ? theme.colorScheme.primary
                : theme.colorScheme.error,
          ),
          const SizedBox(height: 12),
          FrostedDivider(
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '=',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Solde',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                formatter.format(balance),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: balance >= 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLine(
    BuildContext context, {
    required String sign,
    required String label,
    required double amount,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            sign,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          formatter.format(amount),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
