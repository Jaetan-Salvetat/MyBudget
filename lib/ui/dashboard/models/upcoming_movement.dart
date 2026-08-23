import 'package:material_ui/material_ui.dart';

enum MovementDirection { incoming, outgoing }

class UpcomingMovement {
  final String id;
  final String name;
  final double amount;
  final DateTime date;
  final MovementDirection direction;
  final IconData icon;
  final Color color;
  final String? payee;

  const UpcomingMovement({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    required this.direction,
    required this.icon,
    required this.color,
    this.payee,
  });
}
