import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/formatting/date_formatter.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/models/receipt_scan_result_model.dart';
import 'package:mybudget/ui/common/widgets/eyebrow.dart';

class ScanOutputSummary extends StatelessWidget {
  const ScanOutputSummary({
    required this.result,
    required this.resolve,
    super.key,
  });
  final ReceiptScanResultModel result;
  final CategoryDisplay? Function(String? slug) resolve;

  static String titleOf(int count) {
    if (count == 0) return 'Aucune dépense à créer';
    if (count == 1) return '1 dépense à créer';
    return '$count dépenses à créer';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = result.groupedByCategory;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FrostedSpacing.sp5,
        FrostedSpacing.sp4,
        FrostedSpacing.sp5,
        FrostedSpacing.sp5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FrostedDivider(),
          const SizedBox(height: FrostedSpacing.sp3),
          Eyebrow(titleOf(groups.length)),
          const SizedBox(height: FrostedSpacing.sp2),
          for (final group in groups)
            _GroupLine(group: group, category: resolve(group.slug)),
          if (result.storeName != null) ...[
            const SizedBox(height: FrostedSpacing.sp2),
            Text(
              'Nommées « ${result.storeName} — catégorie », '
              'datées du ${DateFormatter.longDate.format(result.date)}, '
              'photo conservée.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupLine extends StatelessWidget {
  const _GroupLine({required this.group, required this.category});
  final ScannedExpenseGroup group;
  final CategoryDisplay? category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FrostedSpacing.sp1),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: category == null
                  ? theme.colorScheme.onSurfaceVariant
                  : Color(category!.color),
            ),
          ),
          const SizedBox(width: FrostedSpacing.sp3),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    category?.label ?? group.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: FrostedSpacing.sp2),
                Text(
                  '${group.count}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: FrostedSpacing.sp2),
          Text(
            MoneyFormatter.format(group.total),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
