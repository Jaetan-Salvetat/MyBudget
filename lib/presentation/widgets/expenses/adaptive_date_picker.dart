import 'package:flutter/material.dart';

class AdaptiveDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final String frequency;
  final Function(DateTime) onDateChanged;

  const AdaptiveDatePicker({
    required this.selectedDate,
    required this.frequency,
    required this.onDateChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          switch (frequency) {
            case 'Unique':
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (pickedDate != null) {
                onDateChanged(pickedDate);
              }
              break;
              
            case 'Mensuel':
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sélectionner le jour du mois'),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 300,
                    child: ListView.builder(
                      itemCount: 31,
                      itemBuilder: (context, index) {
                        final day = index + 1;
                        return ListTile(
                          title: Text('$day'),
                          onTap: () {
                            onDateChanged(DateTime(selectedDate.year, 
                              selectedDate.month, day));
                            Navigator.pop(context);
                          },
                          selected: selectedDate.day == day,
                        );
                      },
                    ),
                  ),
                ),
              );
              break;
              
            case 'Hebdomadaire':
              final days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 
                'Vendredi', 'Samedi', 'Dimanche'];
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sélectionner le jour de la semaine'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      itemCount: days.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(days[index]),
                          onTap: () {
                            int selectedDay = index + 1;
                            if (selectedDay == 7) selectedDay = 0;
                            onDateChanged(_findNextWeekday(selectedDay));
                            Navigator.pop(context);
                          },
                          selected: selectedDate.weekday == index + 1 ||
                            (index == 6 && selectedDate.weekday == 0),
                        );
                      },
                    ),
                  ),
                ),
              );
              break;
              
            case 'Annuel':
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sélectionner le mois'),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 300,
                    child: ListView.builder(
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final months = ['Janvier', 'Février', 'Mars', 'Avril', 
                          'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 
                          'Octobre', 'Novembre', 'Décembre'];
                        return ListTile(
                          title: Text(months[index]),
                          onTap: () {
                            onDateChanged(DateTime(selectedDate.year, 
                              index + 1, selectedDate.day));
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Sélectionner le jour'),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  height: 300,
                                  child: ListView.builder(
                                    itemCount: _daysInMonth(index + 1, selectedDate.year),
                                    itemBuilder: (context, dayIndex) {
                                      final day = dayIndex + 1;
                                      return ListTile(
                                        title: Text('$day'),
                                        onTap: () {
                                          onDateChanged(DateTime(selectedDate.year, 
                                            index + 1, day));
                                          Navigator.pop(context);
                                        },
                                        selected: selectedDate.day == day && 
                                          selectedDate.month == index + 1,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                            Navigator.pop(context);
                          },
                          selected: selectedDate.month == index + 1,
                        );
                      },
                    ),
                  ),
                ),
              );
              break;
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.calendar_today),
          ),
          child: Text(
            _formatDateBasedOnFrequency(),
          ),
        ),
      ),
    );
  }

  String _formatDateBasedOnFrequency() {
    switch (frequency) {
      case 'Unique':
        return '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
      case 'Mensuel':
        return 'Jour ${selectedDate.day} de chaque mois';
      case 'Hebdomadaire':
        final days = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
        return days[selectedDate.weekday % 7];
      case 'Annuel':
        final months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 
                       'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
        return '${selectedDate.day} ${months[selectedDate.month - 1]}';
      default:
        return '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
    }
  }
  
  DateTime _findNextWeekday(int weekday) {
    DateTime date = DateTime.now();
    while (date.weekday != weekday) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }
  
  int _daysInMonth(int month, int year) {
    return DateTime(year, month + 1, 0).day;
  }
}
