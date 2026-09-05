import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/common/widgets/section_header.dart';
import 'package:mybudget/ui/common/widgets/solid_card.dart';
import 'package:mybudget/ui/stats/models/category_trend.dart';

class CategoryBreakdownSection extends StatelessWidget {
  final List<CategoryTrend> categories;
  final int maxVisible;
  final ValueChanged<String>? onCategoryTap;

  const CategoryBreakdownSection({
    super.key,
    required this.categories,
    this.maxVisible = 5,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Répartition'),
          SolidCard(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Center(
              child: Text(
                'Aucune dépense sur la période',
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

    final visible = categories.take(maxVisible).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Répartition', trailing: 'tap pour filtrer'),
        SolidCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FrostedStackedBar(
                segments: [
                  for (final category in categories)
                    FrostedBarSegment(
                      value: category.share,
                      color: category.color,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              for (final category in visible)
                _CategoryRow(
                  category: category,
                  onTap: onCategoryTap == null
                      ? null
                      : () => onCategoryTap!(category.groupKey),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryTrend category;
  final VoidCallback? onTap;

  const _CategoryRow({required this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    final finance = context.financeColors;
    final rising = category.delta >= 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        child: Row(
          children: [
            FrostedChartDot(color: category.color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category.label,
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
              '${rising ? '↑' : '↓'} ${(category.share * 100).round()}%',
              textAlign: TextAlign.right,
              style: AppTextStyles.mono(
                fontSize: 10,
                lineHeight: 14,
                color: rising ? finance.expense : finance.income,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 66,
              child: Text(
                _money(category.amount),
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

  String _money(double amount) => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 0,
  ).format(amount);
}
