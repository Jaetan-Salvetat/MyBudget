import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/common/widgets/category_icon.dart';
import 'package:mybudget/ui/common/widgets/section_header.dart';
import 'package:mybudget/ui/common/widgets/solid_card.dart';
import 'package:mybudget/ui/dashboard/models/upcoming_movement.dart';

class UpcomingMovementsSection extends StatelessWidget {
  final List<UpcomingMovement> movements;
  final int maxVisible;

  const UpcomingMovementsSection({
    super.key,
    required this.movements,
    this.maxVisible = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (movements.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'À venir', trailing: '0 ce mois'),
          SolidCard(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Center(
              child: Text(
                'Aucun mouvement à venir ce mois-ci',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final visible = movements.take(maxVisible).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'À venir',
          trailing: '${movements.length} ce mois',
        ),
        SolidCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < visible.length; i++)
                _MovementRow(
                  movement: visible[i],
                  showDivider: i < visible.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MovementRow extends StatelessWidget {
  final UpcomingMovement movement;
  final bool showDivider;

  const _MovementRow({required this.movement, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final finance = context.financeColors;
    final isIncoming = movement.direction == MovementDirection.incoming;
    final amountColor = isIncoming ? finance.income : finance.expense;
    final iconColor = isIncoming ? finance.income : movement.color;
    final iconData = isIncoming ? Icons.savings_rounded : movement.icon;
    final formattedAmount = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    ).format(movement.amount.abs());
    final meta = movement.payee != null && movement.payee!.isNotEmpty
        ? 'Le ${movement.date.day} · ${movement.payee}'
        : 'Le ${movement.date.day}';

    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: scheme.onSurface.withValues(alpha: 0.07),
                  width: 0.5,
                ),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CategoryIcon(
            icon: iconData,
            color: iconColor,
            size: CategoryIconSize.sm,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.name,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 20 / 15,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
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
          const SizedBox(width: 12),
          Text(
            '${isIncoming ? '+' : '−'} $formattedAmount',
            style: AppTextStyles.amount(fontSize: 15, color: amountColor),
          ),
        ],
      ),
    );
  }
}
