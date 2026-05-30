import 'package:flutter/material.dart';

import 'frosted_picker_field.dart';

/// Opens the themed Material date picker dialog.
///
/// Returns the picked [DateTime], or null if dismissed. The dialog inherits
/// the ambient Frosted theme, so colors and shapes follow the seed.
Future<DateTime?> showFrostedDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: helpText,
  );
}

/// A field that displays the selected date and opens [showFrostedDatePicker]
/// on tap.
class FrostedDateField extends StatelessWidget {
  const FrostedDateField({
    required this.value,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    required this.format,
    this.label,
    this.hintText,
    this.enabled = true,
    super.key,
  });

  final DateTime? value;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;

  /// Formats the selected [value] for display (e.g. via `intl`'s DateFormat).
  final String Function(DateTime date) format;

  final String? label;
  final String? hintText;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final DateTime? picked = await showFrostedDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return FrostedPickerField(
      label: label,
      hintText: hintText,
      icon: Icons.calendar_today_outlined,
      text: value == null ? null : format(value!),
      enabled: enabled,
      onTap: () => _pick(context),
    );
  }
}
