import 'package:frosted_ui/frosted_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/common/widgets/category_icon.dart';
import 'package:mybudget/ui/common/widgets/eyebrow.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.account,
    required this.monthlyIncomes,
    required this.monthlyCharges,
    required this.onTap,
  });
  final AccountModel account;
  final double monthlyIncomes;
  final double monthlyCharges;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final finance = context.financeColors;
    final balance = monthlyIncomes - monthlyCharges;
    final isPositive = balance >= 0;
    final balanceColor = isPositive ? finance.income : finance.expense;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
        borderRadius: BorderRadius.circular(FrostedRadius.xl),
        elevation: FrostedGlassElevation.none,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(18),
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
                        Symbols.chevron_right_rounded,
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
                        '${isPositive ? '+' : '−'} ${MoneyFormatter.format(balance.abs())}',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          height: 28 / 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.02 * 24,
                          color: balanceColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
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
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _StatItem(
                              label: 'Entrées',
                              value: MoneyFormatter.formatRounded(
                                monthlyIncomes,
                              ),
                              color: finance.income,
                            ),
                          ),
                          Container(
                            width: 1,
                            color: scheme.onSurface.withValues(alpha: 0.08),
                          ),
                          Expanded(
                            child: _StatItem(
                              label: 'Charges',
                              value: MoneyFormatter.formatRounded(
                                monthlyCharges,
                              ),
                              color: finance.expense,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.eyebrowMono(
              color: scheme.onSurfaceVariant,
            ).copyWith(fontSize: 11, height: 14 / 11, letterSpacing: 0.08 * 11),
          ),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.amount(fontSize: 18, color: color)),
        ],
      ),
    );
  }
}
