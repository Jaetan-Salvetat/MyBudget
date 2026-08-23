import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/enums/revenue_group_by.dart';

IconData revenueGroupByIcon(RevenueGroupBy axis) => switch (axis) {
  RevenueGroupBy.frequency => Symbols.autorenew_rounded,
  RevenueGroupBy.category => Symbols.category_rounded,
  RevenueGroupBy.beneficiary => Symbols.person_rounded,
  RevenueGroupBy.account => Symbols.account_balance_rounded,
  RevenueGroupBy.none => Symbols.list_rounded,
};

class RevenueGroupByMenu {
  const RevenueGroupByMenu._();

  static void show({
    required BuildContext context,
    required RevenueGroupBy current,
    required ValueChanged<RevenueGroupBy> onSelect,
  }) {
    showFrostedBottomSheet<void>(
      context: context,
      builder: (sheetContext) => FrostedBottomSheet(
        title: 'Regrouper par',
        child: FrostedListSection(
          tiles: [
            for (final axis in RevenueGroupBy.values)
              _tile(
                sheetContext,
                axis: axis,
                selected: axis == current,
                onSelect: onSelect,
              ),
          ],
        ),
      ),
    );
  }

  static FrostedListTile _tile(
    BuildContext context, {
    required RevenueGroupBy axis,
    required bool selected,
    required ValueChanged<RevenueGroupBy> onSelect,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return FrostedListTile(
      title: axis.label,
      leading: Icon(
        revenueGroupByIcon(axis),
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      trailing: selected
          ? Icon(Symbols.check_rounded, color: scheme.primary)
          : null,
      onTap: () {
        Navigator.pop(context);
        onSelect(axis);
      },
    );
  }
}
