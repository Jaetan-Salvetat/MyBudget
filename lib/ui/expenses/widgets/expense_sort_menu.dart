import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/enums/expense_sort_by.dart';

class ExpenseSortMenu {
  const ExpenseSortMenu._();

  static void show({
    required BuildContext context,
    required ExpenseSortBy current,
    required ValueChanged<ExpenseSortBy> onSelect,
  }) {
    FrostedBottomSheet.show(
      context: context,
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
      leading: Icon(
        _iconFor(option),
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(
        option.label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? scheme.primary : scheme.onSurface,
        ),
      ),
      trailing: selected ? Icon(Icons.check, color: scheme.primary) : null,
      onTap: onTap,
    );
  }

  IconData _iconFor(ExpenseSortBy option) {
    return switch (option) {
      ExpenseSortBy.dateDesc => Icons.arrow_downward,
      ExpenseSortBy.dateAsc => Icons.arrow_upward,
      ExpenseSortBy.amountDesc => Icons.south,
      ExpenseSortBy.amountAsc => Icons.north,
      ExpenseSortBy.name => Icons.sort_by_alpha,
    };
  }
}
