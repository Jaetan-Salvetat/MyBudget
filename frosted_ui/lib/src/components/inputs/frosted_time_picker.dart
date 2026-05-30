import 'package:flutter/material.dart';

import 'frosted_picker_field.dart';

/// Opens the themed Material time picker dialog.
///
/// Returns the picked [TimeOfDay], or null if dismissed. The dialog inherits
/// the ambient Frosted theme.
Future<TimeOfDay?> showFrostedTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  String? helpText,
}) {
  return showTimePicker(
    context: context,
    initialTime: initialTime,
    helpText: helpText,
  );
}

/// A field that displays the selected time and opens [showFrostedTimePicker]
/// on tap.
class FrostedTimeField extends StatelessWidget {
  const FrostedTimeField({
    required this.value,
    required this.onChanged,
    this.label,
    this.hintText,
    this.enabled = true,
    this.glass = false,
    super.key,
  });

  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onChanged;
  final String? label;
  final String? hintText;
  final bool enabled;
  final bool glass;

  Future<void> _pick(BuildContext context) async {
    final TimeOfDay? picked = await showFrostedTimePicker(
      context: context,
      initialTime: value ?? TimeOfDay.now(),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return FrostedPickerField(
      label: label,
      hintText: hintText,
      icon: Icons.schedule_outlined,
      text: value?.format(context),
      enabled: enabled,
      glass: glass,
      onTap: () => _pick(context),
    );
  }
}
