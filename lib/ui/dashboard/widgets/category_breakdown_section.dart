import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/common/widgets/section_header.dart';
import 'package:mybudget/ui/common/widgets/solid_card.dart';
import 'package:mybudget/ui/dashboard/models/category_expense_summary.dart';

class CategoryBreakdownSection extends StatelessWidget {
  final List<CategoryExpenseSummary> categories;
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
          const SectionHeader(title: 'Répartition des dépenses'),
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

    final visible = categories.take(maxVisible).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Répartition des dépenses',
          trailing: 'Tap pour filtrer',
        ),
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
  final List<CategoryExpenseSummary> categories;

  const _StackedBar({required this.categories});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final segments = categories.where((c) => c.percentage > 0).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(9999),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            for (var i = 0; i < segments.length; i++)
              Expanded(
                flex: (segments[i].percentage * 10000).round().clamp(
                  1,
                  1000000,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: segments[i].color,
                    border: i < segments.length - 1
                        ? Border(
                            right: BorderSide(
                              color: scheme.surfaceContainerLow,
                              width: 1,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryExpenseSummary category;
  final VoidCallback? onTap;

  const _CategoryRow({required this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = (category.percentage * 100).round();
    final amount = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 0,
    ).format(category.amount);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: category.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Icon(category.icon, size: 16, color: category.color, fill: 1),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                category.categoryName,
                style: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$pct%',
              style: AppTextStyles.eyebrowMono(
                color: scheme.onSurfaceVariant,
              ).copyWith(fontSize: 12, height: 16 / 12, letterSpacing: 0),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 78,
              child: Text(
                amount,
                textAlign: TextAlign.right,
                style: AppTextStyles.amount(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
