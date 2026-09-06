import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/effective_month.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/formatting/date_formatter.dart';
import 'package:mybudget/utils/history_utils.dart';

class EffectiveMonthField extends StatelessWidget {
  const EffectiveMonthField({
    required this.value,
    required this.frequency,
    required this.anchor,
    required this.now,
    required this.label,
    required this.dueLabel,
    required this.onChanged,
    super.key,
  });
  final EffectiveMonth value;
  final Frequency frequency;
  final DateTime anchor;
  final DateTime now;
  final String label;
  final String dueLabel;
  final ValueChanged<EffectiveMonth> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final takesThisMonth = value == EffectiveMonth.thisMonth;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              const SizedBox(height: FrostedSpacing.sp1),
              Text(
                _dueDescription(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: FrostedSpacing.sp3),
        FrostedSwitch(
          value: takesThisMonth,
          onChanged: (selected) => onChanged(
            selected ? EffectiveMonth.thisMonth : EffectiveMonth.nextMonth,
          ),
        ),
      ],
    );
  }

  String _dueDescription() {
    final due = startDateFor(
      frequency: frequency,
      anchor: anchor,
      asOf: now,
      scope: value,
    );
    return '$dueLabel le ${DateFormatter.dayMonth.format(due)}.';
  }
}
