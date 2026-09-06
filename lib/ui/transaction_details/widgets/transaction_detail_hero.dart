import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/data/model/beneficiary_model.dart';
import 'package:mybudget/ui/common/widgets/eyebrow.dart';
import 'package:mybudget/ui/common/widgets/transaction_avatar.dart';

const String _closedLabel = 'Terminé';

class TransactionDetailHero extends StatelessWidget {
  const TransactionDetailHero({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.amount,
    required this.frequency,
    required this.isIncome,
    required this.isClosed,
    this.beneficiary,
    super.key,
  });
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final BeneficiaryModel? beneficiary;
  final double amount;
  final Frequency frequency;
  final bool isIncome;
  final bool isClosed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final finance = context.financeColors;
    final amountColor = isClosed
        ? scheme.onSurfaceVariant
        : (isIncome ? finance.income : finance.expense);

    return FrostedCard(
      radius: FrostedRadius.xl,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TransactionAvatar(
                color: color,
                icon: icon,
                beneficiary: beneficiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
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
                      subtitle,
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
              _StatusPill(
                label: isClosed ? _closedLabel : frequency.label,
                color: isClosed ? scheme.onSurfaceVariant : color,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Eyebrow(_amountLabel),
          const SizedBox(height: 4),
          Text(
            '${isIncome ? '+' : '−'}${MoneyFormatter.format(amount)}',
            style: AppTextStyles.displaySerifItalic(
              fontSize: 40,
              height: 44 / 40,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  String get _amountLabel {
    return switch (frequency) {
      Frequency.monthly => 'Montant mensuel',
      Frequency.annual => 'Montant annuel',
      Frequency.oneTime => 'Montant',
    };
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.mono(
          fontSize: 11,
          letterSpacingEm: 0.05,
          color: color,
        ),
      ),
    );
  }
}
