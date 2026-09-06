import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/formatting/date_formatter.dart';
import 'package:mybudget/core/providers/selected_month_provider.dart';
import 'package:mybudget/ui/common/widgets/date_selector.dart';

class MonthSelector extends ConsumerWidget {
  const MonthSelector({super.key, this.alignment = Alignment.center});
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final label = DateFormatter.monthYear.format(selectedMonth);
    final capitalizedLabel = label.replaceFirst(
      label[0],
      label[0].toUpperCase(),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: alignment,
        child: Material(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(9999),
          child: InkWell(
            borderRadius: BorderRadius.circular(9999),
            onTap: () async {
              final picked = await DateSelector.showMonthYearPicker(
                context: context,
                initialDate: selectedMonth,
              );
              if (picked != null) {
                ref.read(selectedMonthProvider.notifier).setMonth(picked);
              }
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ChevronButton(
                    icon: Symbols.chevron_left_rounded,
                    onPressed: () => ref
                        .read(selectedMonthProvider.notifier)
                        .previousMonth(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      capitalizedLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 16 / 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  _ChevronButton(
                    icon: Symbols.chevron_right_rounded,
                    onPressed: () =>
                        ref.read(selectedMonthProvider.notifier).nextMonth(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChevronButton extends StatelessWidget {
  const _ChevronButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(9999),
      onTap: onPressed,
      child: SizedBox(
        width: 26,
        height: 26,
        child: Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
