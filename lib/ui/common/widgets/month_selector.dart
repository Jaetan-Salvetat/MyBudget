import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/providers/selected_month_provider.dart';
import 'package:mybudget/ui/common/widgets/date_selector.dart';

class MonthSelector extends ConsumerWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final label = DateFormat('MMMM yyyy', 'fr_FR').format(selectedMonth);
    final capitalizedLabel = label.replaceFirst(label[0], label[0].toUpperCase());

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ChevronButton(
            icon: Icons.chevron_left,
            onPressed: () => ref.read(selectedMonthProvider.notifier).previousMonth(),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () async {
              final picked = await DateSelector.showMonthYearPicker(
                context: context,
                initialDate: selectedMonth,
              );
              if (picked != null) {
                ref.read(selectedMonthProvider.notifier).setMonth(picked);
              }
            },
            child: Container(
              constraints: const BoxConstraints(minWidth: 160),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                capitalizedLabel,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _ChevronButton(
            icon: Icons.chevron_right,
            onPressed: () => ref.read(selectedMonthProvider.notifier).nextMonth(),
          ),
        ],
      ),
    );
  }
}

class _ChevronButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ChevronButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
