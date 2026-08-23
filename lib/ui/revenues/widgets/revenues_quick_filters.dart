import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/enums/revenue_group_by.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/ui/revenues/widgets/revenue_group_by_chip.dart';

/// Grouping axis and one-tap category filters, on the row the axis chip used
/// to hold alone.
class RevenuesQuickFilters extends StatelessWidget {
  final RevenueGroupBy axis;
  final List<CategoryDisplay> categories;
  final List<String> selectedGroupKeys;
  final VoidCallback onOpenGroupBy;
  final ValueChanged<String> onCategoryTap;
  final VoidCallback onClear;

  const RevenuesQuickFilters({
    required this.axis,
    required this.categories,
    required this.selectedGroupKeys,
    required this.onOpenGroupBy,
    required this.onCategoryTap,
    required this.onClear,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allSelected = selectedGroupKeys.isEmpty;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          RevenueGroupByChip(axis: axis, onTap: onOpenGroupBy),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 22,
            color: scheme.onSurface.withValues(alpha: 0.08),
          ),
          const SizedBox(width: 8),
          FrostedChip.filter(
            label: 'Toutes',
            selected: allSelected,
            avatar: Icon(
              Symbols.tune_rounded,
              size: 14,
              color: allSelected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            onSelected: (_) => onClear(),
          ),
          for (final category in categories) ...[
            const SizedBox(width: 6),
            FrostedChip.filter(
              label: category.label,
              selected: selectedGroupKeys.contains(category.slug),
              avatar: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(category.color).withValues(
                    alpha: selectedGroupKeys.contains(category.slug)
                        ? 0.9
                        : 0.6,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              onSelected: (_) => onCategoryTap(category.slug),
            ),
          ],
        ],
      ),
    );
  }
}
