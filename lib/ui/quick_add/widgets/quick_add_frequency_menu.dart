import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/enums/frequency.dart';

IconData quickAddFrequencyIcon(Frequency frequency) => switch (frequency) {
  Frequency.oneTime => Symbols.bolt_rounded,
  Frequency.monthly => Symbols.autorenew_rounded,
  Frequency.annual => Symbols.calendar_month_rounded,
};

class QuickAddFrequencyMenu {
  static const String title = 'Rythme';

  static const List<Frequency> options = [
    Frequency.oneTime,
    Frequency.monthly,
    Frequency.annual,
  ];

  const QuickAddFrequencyMenu._();

  static void show({
    required BuildContext context,
    required Frequency current,
    required ValueChanged<Frequency> onSelect,
  }) {
    showFrostedBottomSheet<void>(
      context: context,
      builder: (sheetContext) => FrostedBottomSheet(
        title: title,
        child: FrostedListSection(
          tiles: [
            for (final frequency in options)
              _tile(
                sheetContext,
                frequency: frequency,
                selected: frequency == current,
                onSelect: onSelect,
              ),
          ],
        ),
      ),
    );
  }

  static FrostedListTile _tile(
    BuildContext context, {
    required Frequency frequency,
    required bool selected,
    required ValueChanged<Frequency> onSelect,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return FrostedListTile(
      title: frequency.label,
      leading: Icon(
        quickAddFrequencyIcon(frequency),
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      trailing: selected
          ? Icon(Symbols.check_rounded, color: scheme.primary)
          : null,
      onTap: () {
        Navigator.pop(context);
        onSelect(frequency);
      },
    );
  }
}
