import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/common/widgets/transaction_actions_sheet.dart';
import 'package:mybudget/ui/common/widgets/transaction_avatar.dart';

class CompactRevenueRow extends StatelessWidget {
  final RevenueModel revenue;
  final String accountName;
  final Beneficiary? beneficiary;
  final CategoryDisplay? category;
  final bool showDivider;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CompactRevenueRow({
    required this.revenue,
    required this.accountName,
    required this.onEdit,
    required this.onDelete,
    this.beneficiary,
    this.category,
    this.showDivider = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final finance = context.financeColors;
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    final letter = switch (revenue.frequencyEnum) {
      Frequency.monthly => 'M',
      Frequency.annual => 'A',
      Frequency.oneTime => null,
    };
    final badgeColor = revenue.frequencyEnum == Frequency.monthly
        ? scheme.primary
        : scheme.secondary;
    final categoryColor = category != null
        ? Color(category!.color)
        : finance.income;

    final dateLabel = switch (revenue.frequencyEnum) {
      Frequency.monthly => 'Le ${revenue.startDate.day}',
      Frequency.annual => DateFormat(
        "'Le' d MMMM",
        'fr_FR',
      ).format(revenue.startDate),
      Frequency.oneTime => DateFormat(
        'd MMMM',
        'fr_FR',
      ).format(revenue.startDate),
    };

    final metaParts = <String>[
      dateLabel,
      if (category != null) category!.label,
      accountName,
      if (beneficiary != null) beneficiary!.name,
    ];

    return InkWell(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom: BorderSide(
                    width: 0.5,
                    color: scheme.onSurface.withValues(alpha: 0.06),
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            TransactionAvatar(
              color: categoryColor,
              icon: category == null
                  ? Symbols.savings_rounded
                  : CategoryDefaults.resolveIcon(category!.icon),
              beneficiary: beneficiary,
              badgeLetter: letter,
              badgeColor: badgeColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    revenue.name,
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
                    metaParts.join(' · '),
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
            Text(
              '+ ${formatter.format(revenue.amount).replaceAll('−', '').replaceAll('-', '').trim()}',
              style: TextStyle(
                fontSize: 15,
                height: 20 / 15,
                fontWeight: FontWeight.w600,
                color: finance.income,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 18,
                icon: const Icon(Symbols.more_vert_rounded),
                color: scheme.onSurfaceVariant,
                onPressed: () => _showOptionsBottomSheet(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context) {
    TransactionActionsSheet.show(
      context: context,
      deleteConfirmationMessage: 'Voulez-vous vraiment supprimer ce revenu ?',
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }
}
