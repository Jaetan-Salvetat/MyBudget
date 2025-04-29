import 'package:flutter/material.dart';

class AppDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;
  final String label;
  final IconData icon;

  const AppDatePicker({
    required this.selectedDate,
    required this.onDateChanged,
    required this.label,
    this.icon = Icons.calendar_today,
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
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (pickedDate != null) {
            onDateChanged(pickedDate);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: Icon(icon),
          ),
          child: Text(
            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
          ),
        ),
      ),
    );
  }
}
