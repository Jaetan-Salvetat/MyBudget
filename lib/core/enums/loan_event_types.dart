enum LoanEventType {
  earlyRepaymentTotal('Remboursement anticipé total'),

  earlyRepaymentPartial('Remboursement anticipé partiel');

  const LoanEventType(this.label);

  final String label;
}

enum ReamortizationMode {
  reduceDuration('Réduire la durée', 'La mensualité reste identique'),

  reducePayment('Réduire la mensualité', 'La durée reste identique');

  const ReamortizationMode(this.label, this.description);

  final String label;
  final String description;
}

enum EarlyRepaymentExemption {
  none('Aucun motif d\'exonération'),

  propertySaleAfterRelocation('Vente du bien suite à mutation professionnelle'),

  death('Décès de l\'emprunteur ou de son conjoint'),

  forcedJobLoss('Cessation forcée de l\'activité professionnelle');

  const EarlyRepaymentExemption(this.label);

  final String label;

  bool get exempts => this != EarlyRepaymentExemption.none;
}
