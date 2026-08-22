import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/ui/common/widgets/search_input.dart';

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
          child: SearchInput(
            controller: controller,
            onChanged: onChanged,
            hintText: hintText,
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
                    Symbols.tune_rounded,
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
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
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
