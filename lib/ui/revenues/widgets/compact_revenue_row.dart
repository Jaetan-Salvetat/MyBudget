import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/recurring_deletion.dart';
import 'package:mybudget/core/formatting/date_formatter.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/common/widgets/transaction_actions_sheet.dart';
import 'package:mybudget/ui/common/widgets/transaction_avatar.dart';
import 'package:mybudget/utils/history_utils.dart';

class CompactRevenueRow extends StatelessWidget {
  final RevenueModel revenue;
  final String accountName;
  final Beneficiary? beneficiary;
  final CategoryDisplay? category;
  final bool showDivider;

  final bool isCurrentMonth;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final ValueChanged<RecurringDeletion> onDelete;

  const CompactRevenueRow({
    required this.revenue,
    required this.accountName,
    required this.isCurrentMonth,
    required this.onOpen,
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

    final categoryColor = category != null
        ? Color(category!.color)
        : finance.income;

    final dateLabel = switch (revenue.frequencyEnum) {
      Frequency.monthly => 'Le ${revenue.startDate.day}',
      Frequency.annual => 'Le ${DateFormatter.dayMonth.format(revenue.startDate)}',
      Frequency.oneTime => DateFormatter.dayMonth.format(revenue.startDate),
    };

    final metaParts = <String>[
      dateLabel,
      if (category != null) category!.label,
      accountName,
      if (beneficiary != null) beneficiary!.name,
    ];

    return InkWell(
      onTap: onOpen,
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
              '+ ${MoneyFormatter.format(revenue.amount).replaceAll('−', '').replaceAll('-', '').trim()}',
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
              child: _isReadOnly
                  ? null
                  : IconButton(
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

  bool get _isReadOnly => !isCurrentMonth || revenue.endDate != null;

  RecurringDeletion? get _initialDeletionScope => initialDeletionScopeOf(
    revenue.startDate,
    revenue.endDate,
    revenue.frequencyEnum,
    DateTime.now(),
  );

  void _showOptionsBottomSheet(BuildContext context) {
    TransactionActionsSheet.show(
      context: context,
      initialScope: _initialDeletionScope,
      deleteConfirmationMessage: 'Voulez-vous vraiment supprimer ce revenu ?',
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }
}
