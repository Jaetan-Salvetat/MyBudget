enum LoanRepaymentType {
  amortizable('Amortissable', 'Remboursement progressif du capital'),

  inFine('In Fine', 'Capital remboursé en une fois à la fin');

  final String label;
  final String description;

  const LoanRepaymentType(this.label, this.description);
}

enum InsuranceCalculationMode {
  initialCapital(
    'Capital Initial',
    'Mensualité d\'assurance fixe pendant toute la durée',
  ),

  remainingCapital(
    'Capital Restant Dû',
    'Mensualité d\'assurance qui diminue chaque année',
  );

  final String label;
  final String description;

  const InsuranceCalculationMode(this.label, this.description);
}
