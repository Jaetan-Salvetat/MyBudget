import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/enums/frequency.dart';

class FrequencyDateSection extends StatefulWidget {
  final Frequency frequency;
  final DateTime date;
  final Function(Frequency, DateTime) onChanged;

  const FrequencyDateSection({
    required this.frequency,
    required this.date,
    required this.onChanged,
    super.key,
  });

  @override
  State<FrequencyDateSection> createState() => _FrequencyDateSectionState();
}

class _FrequencyDateSectionState extends State<FrequencyDateSection> {
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
          children:
              Frequency.values.map((freq) {
                final isSelected = widget.frequency == freq;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FrostedChip(
                    label: Text(freq.label),
                    selected: isSelected,
                    onPressed: () {
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
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
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

  String _formatDate(DateTime date) {
    if (widget.frequency == Frequency.monthly) {
      return 'Le ${date.day} du mois';
    } else {
      return DateFormat('d MMMM', 'fr_FR').format(date);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    if (widget.frequency == Frequency.monthly) {
      await _selectDayOnly(context);
    } else {
      await _selectDayAndMonth(context);
    }
  }

  Future<void> _selectDayOnly(BuildContext context) async {
    await FrostedDialog.show(
      context: context,
      title: const Text('Choisir le jour du mois'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: 31,
          itemBuilder: (context, index) {
            final day = index + 1;
            final isSelected = widget.date.day == day;
            return _DateSelectionItem(
              label: '$day',
              isSelected: isSelected,
              onTap: () {
                final newDate = DateTime(
                  widget.date.year,
                  widget.date.month,
                  day,
                );
                widget.onChanged(widget.frequency, newDate);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
      actions: [
        FrostedTextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  }

  Future<void> _selectDayAndMonth(BuildContext context) async {
    int tempMonth = widget.date.month;
    int tempDay = widget.date.day;

    await FrostedDialog.show(
      context: context,
      title: const Text('Choisir la date'),
      content: StatefulBuilder(
        builder: (context, setStateDialog) {
          final daysInMonth = DateTime(2024, tempMonth + 1, 0).day;
          if (tempDay > daysInMonth) tempDay = daysInMonth;

          return SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mois',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 2.5,
                        ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final month = index + 1;
                      final isSelected = tempMonth == month;
                      final monthName = DateFormat(
                        'MMM',
                        'fr_FR',
                      ).format(DateTime(2024, month));
                      final label = monthName.replaceFirst(
                        monthName[0],
                        monthName[0].toUpperCase(),
                      );

                      return _DateSelectionItem(
                        label: label,
                        isSelected: isSelected,
                        onTap: () {
                          setStateDialog(() {
                            tempMonth = month;
                          });
                        },
                        fontSize: 12,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Jour',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                    itemCount: daysInMonth,
                    itemBuilder: (context, index) {
                      final day = index + 1;
                      final isSelected = tempDay == day;
                      return _DateSelectionItem(
                        label: '$day',
                        isSelected: isSelected,
                        onTap: () {
                          setStateDialog(() {
                            tempDay = day;
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        FrostedTextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FrostedFilledButton(
          onPressed: () {
            final newDate = DateTime(widget.date.year, tempMonth, tempDay);
            widget.onChanged(widget.frequency, newDate);
            Navigator.pop(context);
          },
          child: const Text('Valider'),
        ),
      ],
    );
  }
}

class _DateSelectionItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double fontSize;

  const _DateSelectionItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}
