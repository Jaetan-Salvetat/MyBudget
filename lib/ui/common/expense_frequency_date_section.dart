import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/ui/common/widgets/date_selector.dart';

class ExpenseFrequencyDateSection extends StatefulWidget {
  const ExpenseFrequencyDateSection({
    required this.frequency,
    required this.date,
    required this.onChanged,
    super.key,
  });
  final Frequency frequency;
  final DateTime date;
  final void Function(Frequency, DateTime) onChanged;

  @override
  State<ExpenseFrequencyDateSection> createState() =>
      _ExpenseFrequencyDateSectionState();
}

class _ExpenseFrequencyDateSectionState
    extends State<ExpenseFrequencyDateSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Planification',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: Frequency.values.map((freq) {
            final isSelected = widget.frequency == freq;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FrostedChip.filter(
                label: freq.label,
                selected: isSelected,
                onSelected: (_) {
                  if (!isSelected) {
                    widget.onChanged(freq, widget.date);
                  }
                },
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(12),
          child: FrostedCard(
            radius: FrostedRadius.md,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(
                  Symbols.calendar_today_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(widget.date),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) =>
      DateSelector.labelFor(widget.frequency, date);

  Future<void> _selectDate(BuildContext context) async {
    final picked = await DateSelector.showFor(
      context: context,
      frequency: widget.frequency,
      initialDate: widget.date,
    );
    if (picked == null) return;

    widget.onChanged(widget.frequency, picked);
  }
}
