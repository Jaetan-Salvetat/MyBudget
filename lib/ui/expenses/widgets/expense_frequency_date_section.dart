import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseFrequencyDateSection extends StatefulWidget {
  final String frequency;
  final DateTime date;
  final Function(String, DateTime) onChanged;

  const ExpenseFrequencyDateSection({
    required this.frequency,
    required this.date,
    required this.onChanged,
    super.key,
  });

  @override
  State<ExpenseFrequencyDateSection> createState() =>
      _ExpenseFrequencyDateSectionState();
}

class _ExpenseFrequencyDateSectionState
    extends State<ExpenseFrequencyDateSection> {
  final List<String> _frequencies = ['Mensuel', 'Annuel'];

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
              _frequencies.map((freq) {
                final isSelected = widget.frequency == freq;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(freq),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                         
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
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(_formatDate(widget.date)),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    if (widget.frequency == 'Mensuel') {
      return 'Le ${date.day} du mois';
    } else {
       
      return DateFormat('d MMMM', 'fr_FR').format(date);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    if (widget.frequency == 'Mensuel') {
      await _selectDayOnly(context);
    } else {
      await _selectDayAndMonth(context);
    }
  }

  Future<void> _selectDayOnly(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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
                return InkWell(
                  onTap: () {
                    final newDate = DateTime(
                      widget.date.year,
                      widget.date.month,
                      day,
                    );
                    widget.onChanged(widget.frequency, newDate);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color:
                            isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDayAndMonth(BuildContext context) async {
    int tempMonth = widget.date.month;
    int tempDay = widget.date.day;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final daysInMonth = DateTime(2024, tempMonth + 1, 0).day;
            if (tempDay > daysInMonth) tempDay = daysInMonth;

            return AlertDialog(
              title: const Text('Choisir la date'),
              content: SizedBox(
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

                          return InkWell(
                            onTap: () {
                              setStateDialog(() {
                                tempMonth = month;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                label,
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.onPrimary
                                          : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
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
                          return InkWell(
                            onTap: () {
                              setStateDialog(() {
                                tempDay = day;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.onPrimary
                                          : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () {
                    final newDate = DateTime(
                      widget.date.year,
                      tempMonth,
                      tempDay,
                    );
                    widget.onChanged(widget.frequency, newDate);
                    Navigator.pop(context);
                  },
                  child: const Text('Valider'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
