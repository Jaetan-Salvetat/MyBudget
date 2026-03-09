import 'package:flutter/material.dart';

class BeneficiaryAvatar extends StatelessWidget {
  final String name;
  final double radius;

  const BeneficiaryAvatar({
    required this.name,
    this.radius = 20,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        name.isNotEmpty ? name[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }
}
