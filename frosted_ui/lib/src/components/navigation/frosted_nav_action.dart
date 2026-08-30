import 'package:flutter/widgets.dart';

class FrostedNavAction {
  const FrostedNavAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;

  final String label;

  final VoidCallback onPressed;
}
