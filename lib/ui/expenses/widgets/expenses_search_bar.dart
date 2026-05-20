import 'package:flutter/material.dart';
import 'package:mybudget/core/theme/finance_colors.dart';

class ExpensesSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final int activeFiltersCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onOpenFilters;
  final String hintText;

  const ExpensesSearchBar({
    required this.controller,
    required this.activeFiltersCount,
    required this.onChanged,
    required this.onOpenFilters,
    this.hintText = 'Rechercher un nom, un bénéficiaire…',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasFilters = activeFiltersCount > 0;
    final finance = context.financeColors;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(
                width: 1,
                color: scheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 18 / 13.5,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      hintText: hintText,
                      hintStyle: TextStyle(
                        fontSize: 13.5,
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      controller.clear();
                      onChanged('');
                    },
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.close,
                        size: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: hasFilters
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
                side: hasFilters
                    ? BorderSide.none
                    : BorderSide(
                        width: 1,
                        color: scheme.onSurface.withValues(alpha: 0.08),
                      ),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onOpenFilters,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.tune,
                    size: 20,
                    color: hasFilters ? scheme.onPrimary : scheme.onSurface,
                  ),
                ),
              ),
            ),
            if (hasFilters)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: finance.expense,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(width: 1.5, color: scheme.surface),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$activeFiltersCount',
                    style: const TextStyle(
                      fontSize: 9,
                      height: 14 / 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
