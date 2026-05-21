import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/enums/expense_sort_by.dart';
import 'package:mybudget/models/category_model.dart';

class ExpensesQuickFilters extends StatelessWidget {
  final List<CategoryModel> categories;
  final List<int> selectedCategoryIds;
  final ExpenseSortBy sortBy;
  final VoidCallback onOpenSort;
  final ValueChanged<int?> onCategoryTap;

  const ExpensesQuickFilters({
    required this.categories,
    required this.selectedCategoryIds,
    required this.sortBy,
    required this.onOpenSort,
    required this.onCategoryTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allSelected = selectedCategoryIds.isEmpty;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _SortChip(label: sortBy.label, onTap: onOpenSort),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 22,
            color: scheme.onSurface.withValues(alpha: 0.08),
          ),
          const SizedBox(width: 8),
          FrostedChip(
            label: const Text('Toutes'),
            selected: allSelected,
            avatar: Icon(
              Symbols.tune_rounded,
              size: 14,
              color: allSelected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            onPressed: () => onCategoryTap(null),
          ),
          for (final category in categories) ...[
            const SizedBox(width: 6),
            FrostedChip(
              label: Text(category.name),
              selected: selectedCategoryIds.contains(category.id),
              selectedColor: Color(category.color),
              avatar: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(category.color).withValues(
                    alpha:
                        selectedCategoryIds.contains(category.id) ? 0.9 : 0.6,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              onPressed: () => onCategoryTap(category.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SortChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.06),
          border: Border.all(
            width: 1,
            color: scheme.onSurface.withValues(alpha: 0.10),
          ),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.swap_vert_rounded, size: 14, color: scheme.onSurface),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                height: 16 / 12.5,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              Symbols.expand_more_rounded,
              size: 14,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
