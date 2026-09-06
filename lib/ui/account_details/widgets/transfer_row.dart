import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/data/model/transfer_model.dart';
import 'package:mybudget/ui/common/widgets/category_icon.dart';
import 'package:mybudget/ui/common/widgets/transaction_actions_sheet.dart';

class TransferRow extends StatelessWidget {
  const TransferRow({
    super.key,
    required this.transfer,
    required this.currentAccountId,
    required this.otherAccountName,
    required this.onEdit,
    required this.onDelete,
    this.showDivider = true,
  });
  final TransferModel transfer;
  final int currentAccountId;
  final String otherAccountName;
  final bool showDivider;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  void _showOptionsBottomSheet(BuildContext context) {
    TransactionActionsSheet.show(
      context: context,
      deleteConfirmationMessage: 'Voulez-vous vraiment supprimer ce virement ?',
      onEdit: onEdit,
      onDelete: (_) => onDelete(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final finance = context.financeColors;
    final isOutgoing = transfer.isOutgoingFrom(currentAccountId);
    final amountColor = isOutgoing ? finance.expense : finance.income;
    final signPrefix = isOutgoing ? '− ' : '+ ';

    final directionLabel = isOutgoing
        ? 'Vers $otherAccountName'
        : 'Depuis $otherAccountName';

    final freqLabel = transfer.frequencyEnum.label;
    final day = transfer.startDate.day;
    final meta = transfer.frequencyEnum == Frequency.oneTime
        ? freqLabel
        : '$freqLabel · Le $day';

    return InkWell(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
        child: Row(
          children: [
            CategoryIcon(
              icon: Symbols.swap_horiz_rounded,
              color: scheme.secondary,
              size: CategoryIconSize.sm,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    directionLabel,
                    style: TextStyle(
                      fontSize: 15,
                      height: 20 / 15,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface,
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
              '$signPrefix${MoneyFormatter.format(transfer.amount.abs())}',
              style: AppTextStyles.amount(fontSize: 15, color: amountColor),
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
}
