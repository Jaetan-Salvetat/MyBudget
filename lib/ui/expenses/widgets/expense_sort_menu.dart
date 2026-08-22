import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/enums/expense_sort_by.dart';

class ExpenseSortMenu {
  const ExpenseSortMenu._();

  static void show({
    required BuildContext context,
    required ExpenseSortBy current,
    required ValueChanged<ExpenseSortBy> onSelect,
  }) {
    showFrostedBottomSheet<void>(
      context: context,
      builder: (_) => FrostedBottomSheet(
        title: 'Trier par',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in ExpenseSortBy.values)
              _SortMenuTile(
                option: option,
                selected: option == current,
                onTap: () {
                  Navigator.pop(context);
                  onSelect(option);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SortMenuTile extends StatelessWidget {
  final ExpenseSortBy option;
  final bool selected;
  final VoidCallback onTap;

  const _SortMenuTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FrostedListTile(
      title: option.label,
      leading: Icon(
        _iconFor(option),
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      trailing: selected
          ? Icon(Symbols.check_rounded, color: scheme.primary)
          : null,
      onTap: onTap,
    );
  }

  IconData _iconFor(ExpenseSortBy option) {
    return switch (option) {
      ExpenseSortBy.dateDesc => Symbols.arrow_downward_rounded,
      ExpenseSortBy.dateAsc => Symbols.arrow_upward_rounded,
      ExpenseSortBy.amountDesc => Symbols.south_rounded,
      ExpenseSortBy.amountAsc => Symbols.north_rounded,
      ExpenseSortBy.name => Symbols.sort_by_alpha_rounded,
    };
  }
}
