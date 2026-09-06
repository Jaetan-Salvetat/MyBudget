enum LoanRepaymentType {
  amortizable('Amortissable', 'Remboursement progressif du capital'),

  inFine('In Fine', 'Capital remboursé en une fois à la fin');

  const LoanRepaymentType(this.label, this.description);

  final String label;
  final String description;
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

  const InsuranceCalculationMode(this.label, this.description);

  final String label;
  final String description;
}

enum LoanDeferralType {
  none('Aucun', 'Amortissement dès la première échéance'),

  partial(
    'Partiel',
    'Intérêts et assurance payés, le capital n\'est pas amorti',
  ),

  total('Total', 'Seule l\'assurance est payée, les intérêts sont capitalisés');

  const LoanDeferralType(this.label, this.description);

  final String label;
  final String description;
}

enum CreditRegime {
  consumer('Consommation', 'Auto, travaux, trésorerie, paiement fractionné'),

  mortgage('Immobilier', 'Acquisition ou construction d\'un bien');

  const CreditRegime(this.label, this.description);

  final String label;
  final String description;
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

  const LoanPurpose(this.label, this.fixedRegime);

  final String label;
  final CreditRegime? fixedRegime;

  bool get waivesIndemnityByDefault =>
      this == LoanPurpose.family || this == LoanPurpose.bridge;
}
