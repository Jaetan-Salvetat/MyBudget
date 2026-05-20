import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/common/widgets/eyebrow.dart';
import 'package:mybudget/ui/dashboard/widgets/balance_donut.dart';

class HeroBalanceCard extends StatelessWidget {
  final double balance;
  final double totalIncomes;
  final double totalExpenses;

  const HeroBalanceCard({
    super.key,
    required this.balance,
    required this.totalIncomes,
    required this.totalExpenses,
  });

  @override
  Widget build(BuildContext context) {
    final finance = context.financeColors;
    final isPositive = balance >= 0;
    final accentColor = isPositive ? finance.income : finance.expense;
    final progress = totalIncomes > 0
        ? (totalExpenses / totalIncomes).clamp(0.0, 1.0)
        : 0.0;

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
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
      child: FrostedContainer(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 22),
        borderRadius: BorderRadius.circular(28),
        backgroundColor: scheme.surface.withValues(alpha: isDark ? 0.55 : 0.88),
        borderColor: scheme.onSurface.withValues(alpha: isDark ? 0.16 : 0.10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopRow(isPositive: isPositive, accentColor: accentColor),
            const SizedBox(height: 8),
            Center(
              child: BalanceDonut(
                progress: progress,
                arcColor: accentColor,
                child: _CenterAmount(
                  balance: balance,
                  color: accentColor,
                  hint: _hintText(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DirectionChip(
                    label: 'Entrées',
                    amount: totalIncomes,
                    icon: Icons.arrow_downward_rounded,
                    background: finance.incomeSoft,
                    foreground: finance.incomeOnSoft,
                    accent: finance.income,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DirectionChip(
                    label: 'Sorties',
                    amount: totalExpenses,
                    icon: Icons.arrow_upward_rounded,
                    background: finance.expenseSoft,
                    foreground: finance.expenseOnSoft,
                    accent: finance.expense,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _hintText() {
    if (balance < 0) return 'Au-delà du budget';
    if (totalExpenses <= 0) return 'Aucune dépense enregistrée';
    final avgDailyExpense = totalExpenses / 30;
    final daysAhead = (balance / avgDailyExpense).round();
    if (daysAhead <= 0) return 'À l\'équilibre';
    return '≈ $daysAhead jour${daysAhead > 1 ? 's' : ''} d\'avance';
  }
}

class _TopRow extends StatelessWidget {
  final bool isPositive;
  final Color accentColor;

  const _TopRow({required this.isPositive, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Eyebrow('Ton reste à vivre'),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              size: 14,
              color: accentColor,
              fill: 1,
            ),
            const SizedBox(width: 4),
            Text(
              isPositive ? 'on track' : 'attention',
              style: AppTextStyles.eyebrowMono(color: accentColor).copyWith(
                fontSize: 11,
                height: 14 / 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CenterAmount extends StatelessWidget {
  final double balance;
  final Color color;
  final String hint;

  const _CenterAmount({
    required this.balance,
    required this.color,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final parts = _split(balance);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            style: AppTextStyles.heroAmount(color: color),
            children: [
              TextSpan(text: '${parts.sign}${parts.integerPart}'),
              TextSpan(
                text: ',${parts.decimalPart} €',
                style: AppTextStyles.displaySerifItalic(
                  fontSize: 28,
                  color: color.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          hint,
          style: TextStyle(
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  _AmountParts _split(double value) {
    final formatter = NumberFormat.decimalPattern('fr_FR');
    formatter.minimumFractionDigits = 2;
    formatter.maximumFractionDigits = 2;
    final formatted = formatter.format(value.abs());
    final segments = formatted.split(',');
    return _AmountParts(
      sign: value < 0 ? '−' : '',
      integerPart: segments[0],
      decimalPart: segments.length > 1 ? segments[1] : '00',
    );
  }
}

class _AmountParts {
  final String sign;
  final String integerPart;
  final String decimalPart;

  const _AmountParts({
    required this.sign,
    required this.integerPart,
    required this.decimalPart,
  });
}

class _DirectionChip extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color accent;

  const _DirectionChip({
    required this.label,
    required this.amount,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 0,
    ).format(amount.abs());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accent, fill: 1),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(label, color: foreground),
                const SizedBox(height: 2),
                Text(
                  formatted,
                  style: AppTextStyles.amount(
                    fontSize: 15,
                    color: foreground,
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
