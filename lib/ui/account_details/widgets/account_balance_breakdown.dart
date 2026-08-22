import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/common/widgets/section_header.dart';
import 'package:mybudget/ui/common/widgets/solid_card.dart';

class AccountBalanceBreakdown extends StatelessWidget {
  final double totalRevenues;
  final double totalExpenses;
  final double totalLoanPayments;
  final double totalTransfers;
  final double balance;

  const AccountBalanceBreakdown({
    super.key,
    required this.totalRevenues,
    required this.totalExpenses,
    required this.totalLoanPayments,
    required this.totalTransfers,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final finance = context.financeColors;
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );

    String formatSigned(double value, {required bool forceSign}) {
      final sign = value < 0
          ? '− '
          : forceSign
          ? '+ '
          : '';
      return '$sign${formatter.format(value.abs())}';
    }

    final isPositive = balance >= 0;
    final balanceColor = isPositive ? finance.income : finance.expense;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Composition'),
        SolidCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              _DecompRow(
                icon: Symbols.arrow_downward_rounded,
                label: 'Revenus',
                value: '+ ${formatter.format(totalRevenues)}',
                valueColor: finance.income,
              ),
              _DecompRow(
                icon: Symbols.arrow_upward_rounded,
                label: 'Dépenses',
                value: '− ${formatter.format(totalExpenses)}',
                valueColor: finance.expense,
              ),
              _DecompRow(
                icon: Symbols.account_balance_rounded,
                label: 'Mensualités',
                value: '− ${formatter.format(totalLoanPayments)}',
                valueColor: finance.expense,
              ),
              _DecompRow(
                icon: Symbols.swap_horiz_rounded,
                label: 'Virements',
                value: formatSigned(totalTransfers, forceSign: true),
                valueColor: totalTransfers >= 0
                    ? finance.income
                    : finance.expense,
              ),
              const SizedBox(height: 8),
              Container(
                height: 1,
                color: scheme.onSurface.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Solde',
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${isPositive ? '+' : '−'}${formatter.format(balance.abs())}',
                      style: AppTextStyles.amount(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: balanceColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DecompRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _DecompRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                color: scheme.onSurface,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.amount(fontSize: 15, color: valueColor),
          ),
        ],
      ),
    );
  }
}
