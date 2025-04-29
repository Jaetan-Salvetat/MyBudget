import 'package:flutter/material.dart';

class AppDropdownField<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final String label;
  final IconData? icon;

  const AppDropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.label,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.surface,
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: icon != null ? Icon(icon) : null,
        ),
      ),
    );
  }
}
