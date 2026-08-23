import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/ui/common/widgets/transaction_actions_sheet.dart';
import 'package:mybudget/ui/common/widgets/transaction_avatar.dart';

class CompactExpenseRow extends StatelessWidget {
  final ExpenseModel expense;
  final CategoryDisplay? category;
  final Beneficiary? beneficiary;
  final bool showDivider;
  final bool showDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CompactExpenseRow({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
    this.category,
    this.beneficiary,
    this.showDivider = true,
    this.showDate = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final categoryColor = category != null
        ? Color(category!.color)
        : scheme.primary;

    final metaParts = <String>[
      if (showDate) _dateLabel(),
      if (category != null) category!.label,
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
                  ? Symbols.category_rounded
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
                    expense.name,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 20 / 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (metaParts.isNotEmpty) ...[
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
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '− ${formatter.format(expense.amount).replaceAll('−', '').replaceAll('-', '').trim()}',
              style: TextStyle(
                fontSize: 15,
                height: 20 / 15,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
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

  String _dateLabel() {
    return switch (expense.frequencyEnum) {
      Frequency.monthly => 'Le ${expense.startDate.day}',
      Frequency.annual => DateFormat(
        "'Le' d MMMM",
        'fr_FR',
      ).format(expense.startDate),
      Frequency.oneTime => DateFormat(
        'd MMMM',
        'fr_FR',
      ).format(expense.startDate),
    };
  }

  void _showOptionsBottomSheet(BuildContext context) {
    TransactionActionsSheet.show(
      context: context,
      deleteConfirmationMessage: 'Voulez-vous vraiment supprimer cette dépense ?',
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }
}
