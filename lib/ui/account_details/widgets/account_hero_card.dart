import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/common/widgets/category_icon.dart';
import 'package:mybudget/ui/common/widgets/eyebrow.dart';

class AccountHeroCard extends StatelessWidget {
  final AccountModel account;
  final double balance;

  const AccountHeroCard({
    super.key,
    required this.account,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final finance = context.financeColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = balance >= 0;
    final balanceColor = isPositive ? finance.income : finance.expense;

    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: isDark ? 0.30 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: scheme.shadow.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FrostedGlass(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
        borderRadius: BorderRadius.circular(FrostedRadius.xl),
        elevation: FrostedGlassElevation.none,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryIcon(
                  icon: Symbols.account_balance_wallet_rounded,
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
                          height: 20 / 16,
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
              ],
            ),
            const SizedBox(height: 14),
            const Eyebrow('Solde du mois'),
            const SizedBox(height: 4),
            Text(
              '${isPositive ? '+' : '−'}${formatter.format(balance.abs())}',
              style: AppTextStyles.displaySerifItalic(
                fontSize: 48,
                height: 52 / 48,
                color: balanceColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
