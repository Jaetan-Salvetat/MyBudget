import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/common/widgets/category_icon.dart';
import 'package:mybudget/ui/common/widgets/eyebrow.dart';

class AccountCard extends StatelessWidget {
  final AccountModel account;
  final double monthlyIncomes;
  final double monthlyCharges;
  final VoidCallback onTap;

  const AccountCard({
    super.key,
    required this.account,
    required this.monthlyIncomes,
    required this.monthlyCharges,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final finance = context.financeColors;
    final balance = monthlyIncomes - monthlyCharges;
    final isPositive = balance >= 0;
    final balanceColor = isPositive ? finance.income : finance.expense;
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );
    final compactFormatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 0,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: FrostedContainer(
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryIcon(
                  icon: Icons.account_balance_wallet_rounded,
                  color: scheme.primary,
                  size: CategoryIconSize.md,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: TextStyle(
                          fontSize: 16,
                          height: 22 / 16,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        account.bank,
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
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Expanded(child: Eyebrow('Solde du mois')),
                Text(
                  '${isPositive ? '+' : '−'} ${formatter.format(balance.abs())}',
                  style: AppTextStyles.amount(
                    fontSize: 24,
                    color: balanceColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: scheme.onSurface.withValues(alpha: 0.07),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      label: 'Entrées',
                      value: compactFormatter.format(monthlyIncomes),
                      color: finance.income,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: scheme.onSurface.withValues(alpha: 0.08),
                  ),
                  Expanded(
                    child: _StatItem(
                      label: 'Charges',
                      value: compactFormatter.format(monthlyCharges),
                      color: finance.expense,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(label),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.amount(fontSize: 16, color: color),
          ),
        ],
      ),
    );
  }
}
