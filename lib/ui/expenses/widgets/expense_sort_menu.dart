import 'package:material_ui/material_ui.dart';
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
      builder: (sheetContext) => FrostedBottomSheet(
        title: 'Trier par',
        child: FrostedListSection(
          tiles: [
            for (final option in ExpenseSortBy.values)
              _tile(
                sheetContext,
                option: option,
                selected: option == current,
                onSelect: onSelect,
              ),
          ],
        ),
      ),
    );
  }

  static FrostedListTile _tile(
    BuildContext context, {
    required ExpenseSortBy option,
    required bool selected,
    required ValueChanged<ExpenseSortBy> onSelect,
  }) {
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
      onTap: () {
        Navigator.pop(context);
        onSelect(option);
      },
    );
  }

  static IconData _iconFor(ExpenseSortBy option) {
    return switch (option) {
      ExpenseSortBy.dateDesc => Symbols.arrow_downward_rounded,
      ExpenseSortBy.dateAsc => Symbols.arrow_upward_rounded,
      ExpenseSortBy.amountDesc => Symbols.south_rounded,
      ExpenseSortBy.amountAsc => Symbols.north_rounded,
      ExpenseSortBy.name => Symbols.sort_by_alpha_rounded,
    };
  }
}
