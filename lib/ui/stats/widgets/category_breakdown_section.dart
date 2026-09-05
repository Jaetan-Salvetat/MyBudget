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
              _StackedBar(categories: categories),
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

class _StackedBar extends StatelessWidget {
  static const double barHeight = 10;
  static const double segmentGap = 2;

  final List<CategoryTrend> categories;

  const _StackedBar({required this.categories});

  @override
  Widget build(BuildContext context) {
    final segments = categories.where((c) => c.share > 0).toList();

    return SizedBox(
      height: barHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < segments.length; index++) ...[
            if (index > 0) const SizedBox(width: segmentGap),
            Expanded(
              flex: (segments[index].share * 10000).round().clamp(1, 1000000),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: segments[index].color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
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
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: category.color,
                shape: BoxShape.circle,
              ),
            ),
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
