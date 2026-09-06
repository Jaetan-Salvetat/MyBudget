import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/constants/layout_insets.dart';
import 'package:mybudget/core/enums/expense_sort_by.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';

class ExpensesQuickFilters extends StatelessWidget {
  const ExpensesQuickFilters({
    required this.categories,
    required this.selectedGroupKeys,
    required this.sortBy,
    required this.onOpenSort,
    required this.onCategoryTap,
    super.key,
  });
  final List<CategoryDisplay> categories;
  final List<String> selectedGroupKeys;
  final ExpenseSortBy sortBy;
  final VoidCallback onOpenSort;
  final ValueChanged<String?> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allSelected = selectedGroupKeys.isEmpty;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: kMainFlowGutter),
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
          FrostedChip.filter(
            label: 'Toutes',
            selected: allSelected,
            avatar: Icon(
              Symbols.tune_rounded,
              size: 14,
              color: allSelected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            onSelected: (_) => onCategoryTap(null),
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

class _SortChip extends StatelessWidget {
  const _SortChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

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
