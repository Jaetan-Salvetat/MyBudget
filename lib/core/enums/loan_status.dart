enum LoanStatus {
  pending('À commencer'),
  partiallyPaid('En cours'),
  completed('Remboursé');

  const LoanStatus(this.label);

  final String label;
}
