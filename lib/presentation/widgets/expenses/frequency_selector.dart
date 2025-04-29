import 'package:flutter/material.dart';
import 'package:mybudget/presentation/widgets/common/app_dropdown_field.dart';

class FrequencySelector extends StatelessWidget {
  final String selectedFrequency;
  final List<String> frequencies;
  final Function(String) onFrequencyChanged;

  const FrequencySelector({
    required this.selectedFrequency,
    required this.frequencies,
    required this.onFrequencyChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppDropdownField<String>(
      value: selectedFrequency,
      label: 'Fréquence',
      icon: Icons.repeat,
      items:
          frequencies.map((frequency) {
            return DropdownMenuItem(value: frequency, child: Text(frequency));
          }).toList(),
      onChanged: (value) {
        if (value != null) {
          onFrequencyChanged(value);
        }
      },
    );
  }
}
