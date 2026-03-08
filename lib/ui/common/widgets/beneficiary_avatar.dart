import 'package:flutter/material.dart';

/// Avatar circulaire affichant l'initiale d'un bénéficiaire.
/// Utilisé dans la liste des bénéficiaires (Settings) et dans les cartes de dépenses/revenus.
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
