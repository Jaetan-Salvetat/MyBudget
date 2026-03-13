import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/ui/dashboard/models/category_expense_summary.dart';

class CategorySummaryCard extends StatelessWidget {
  final List<CategoryExpenseSummary> categories;
  final NumberFormat formatter;
  final void Function(int categoryId)? onCategoryTap;

  const CategorySummaryCard({
    required this.categories,
    required this.formatter,
    this.onCategoryTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FrostedCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (categories.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Aucune dépense ce mois-ci'),
              ),
            )
          else
            ...categories.map(
              (category) => CategoryProgressItem(
                category: category,
                formatter: formatter,
                onTap: onCategoryTap != null
                    ? () => onCategoryTap!(category.categoryId)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class CategoryProgressItem extends StatelessWidget {
  final CategoryExpenseSummary category;
  final NumberFormat formatter;
  final VoidCallback? onTap;

  const CategoryProgressItem({
    required this.category,
    required this.formatter,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FrostedCard(
      margin: const EdgeInsets.only(bottom: 16),
      borderRadius: 12,
      padding: const EdgeInsets.all(12),
      onClick: onTap,
      accentColor: category.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(category.icon, color: category.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.categoryName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                formatter.format(category.amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: category.percentage.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: category.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${(category.percentage * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
