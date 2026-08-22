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

enum LoanDeferralType {
  none('Aucun', 'Amortissement dès la première échéance'),

  partial(
    'Partiel',
    'Intérêts et assurance payés, le capital n\'est pas amorti',
  ),

  total(
    'Total',
    'Seule l\'assurance est payée, les intérêts sont capitalisés',
  );

  final String label;
  final String description;

  const LoanDeferralType(this.label, this.description);
}

enum CreditRegime {
  consumer(
    'Consommation',
    'Auto, travaux, trésorerie, paiement fractionné',
  ),

  mortgage('Immobilier', 'Acquisition ou construction d\'un bien');

  final String label;
  final String description;

  const CreditRegime(this.label, this.description);
}

enum LoanPurpose {
  mortgage('Prêt immobilier', CreditRegime.mortgage),

  bridge('Prêt relais', CreditRegime.mortgage),

  works('Prêt travaux', null),

  car('Prêt auto ou moto', CreditRegime.consumer),

  personal('Prêt personnel, trésorerie', CreditRegime.consumer),

  student('Prêt étudiant', CreditRegime.consumer),

  instalmentPlan('Paiement en plusieurs fois', CreditRegime.consumer),

  family('Prêt familial, entre particuliers', null),

  other('Autre', null);

  final String label;
  final CreditRegime? fixedRegime;

  const LoanPurpose(this.label, this.fixedRegime);

  bool get waivesIndemnityByDefault =>
      this == LoanPurpose.family || this == LoanPurpose.bridge;
}
