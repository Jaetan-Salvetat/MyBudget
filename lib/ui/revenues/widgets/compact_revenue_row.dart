import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/enums/recurring_deletion.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/enums/frequency.dart';
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

  /// Whether the month being read is the one still in progress.
  final bool isCurrentMonth;
  final VoidCallback onEdit;
  final ValueChanged<RecurringDeletion> onDelete;

  const CompactRevenueRow({
    required this.revenue,
    required this.accountName,
    required this.isCurrentMonth,
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
      onTap: _isReadOnly ? null : onEdit,
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
              '+ ${formatter.format(revenue.amount).replaceAll('−', '').replaceAll('-', '').trim()}',
              style: TextStyle(
                fontSize: 15,
                height: 20 / 15,
                fontWeight: FontWeight.w600,
                color: finance.income,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (!_isReadOnly)
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

  /// A closed rule is a trace, and so is any month that is not the one in
  /// progress : both can be read, neither can be edited or deleted. Acting on
  /// a past month would mean deciding what it should retroactively have been.
  bool get _isReadOnly => !isCurrentMonth || revenue.endDate != null;

  /// The answer the deletion dialog opens on, and null when there is no
  /// month to argue about. A rule that has already been honoured this month
  /// keeps it ; one still waiting for its turn has nothing to keep.
  RecurringDeletion? get _initialDeletionScope {
    if (revenue.frequencyEnum == Frequency.oneTime) return null;

    return hasOccurredThisMonth(
      revenue.startDate,
      revenue.endDate,
      revenue.frequencyEnum,
      DateTime.now(),
    )
        ? RecurringDeletion.afterThisMonth
        : RecurringDeletion.includingThisMonth;
  }

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
