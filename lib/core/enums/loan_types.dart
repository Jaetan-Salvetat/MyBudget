/// Type de remboursement du prêt
enum LoanRepaymentType {
  /// Prêt amortissable : capital remboursé progressivement
  amortizable('Amortissable', 'Remboursement progressif du capital'),

  /// Prêt in fine : capital remboursé à la fin
  inFine('In Fine', 'Capital remboursé en une fois à la fin');

  final String label;
  final String description;

  const LoanRepaymentType(this.label, this.description);
}

/// Mode de calcul de l'assurance emprunteur
enum InsuranceCalculationMode {
  /// Calculé sur le capital initial (mensualité fixe)
  initialCapital(
    'Capital Initial',
    'Mensualité d\'assurance fixe pendant toute la durée',
  ),

  /// Calculé sur le capital restant dû (mensualité dégressive)
  remainingCapital(
    'Capital Restant Dû',
    'Mensualité d\'assurance qui diminue chaque année',
  );

  final String label;
  final String description;

  const InsuranceCalculationMode(this.label, this.description);
}
