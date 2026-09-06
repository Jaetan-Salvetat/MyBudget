import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/core/formatting/percent_formatter.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/common/widgets/section_header.dart';
import 'package:mybudget/ui/common/widgets/solid_card.dart';
import 'package:mybudget/ui/stats/models/category_slice.dart';

class CategoryBreakdownSection extends StatelessWidget {
  final List<CategorySlice> slices;
  final int maxVisible;
  final ValueChanged<String>? onCategoryTap;

  const CategoryBreakdownSection({
    super.key,
    required this.slices,
    this.maxVisible = 5,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Répartition', trailing: 'ce mois-ci'),
          SolidCard(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Center(
              child: Text(
                'Aucune dépense ce mois-ci',
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

    final visible = slices.take(maxVisible).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Répartition', trailing: 'ce mois-ci'),
        SolidCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FrostedStackedBar(
                segments: [
                  for (final slice in slices)
                    FrostedBarSegment(value: slice.share, color: slice.color),
                ],
              ),
              const SizedBox(height: 14),
              for (final slice in visible)
                _CategoryRow(
                  slice: slice,
                  onTap: onCategoryTap == null
                      ? null
                      : () => onCategoryTap!(slice.groupKey),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategorySlice slice;
  final VoidCallback? onTap;

  const _CategoryRow({required this.slice, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        child: Row(
          children: [
            FrostedChartDot(color: slice.color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                slice.label,
                style: const TextStyle(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              PercentFormatter.formatShare(slice.share),
              textAlign: TextAlign.right,
              style: AppTextStyles.mono(
                fontSize: 10,
                lineHeight: 14,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 66,
              child: Text(
                MoneyFormatter.formatRounded(slice.amount),
                textAlign: TextAlign.right,
                style: AppTextStyles.mono(
                  fontSize: 12,
                  lineHeight: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
