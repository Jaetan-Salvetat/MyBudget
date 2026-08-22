enum LoanEventType {
  earlyRepaymentTotal('Remboursement anticipé total'),

  earlyRepaymentPartial('Remboursement anticipé partiel');

  final String label;

  const LoanEventType(this.label);
}

enum ReamortizationMode {
  reduceDuration('Réduire la durée', 'La mensualité reste identique'),

  reducePayment('Réduire la mensualité', 'La durée reste identique');

  final String label;
  final String description;

  const ReamortizationMode(this.label, this.description);
}

enum EarlyRepaymentExemption {
  none('Aucun motif d\'exonération'),

  propertySaleAfterRelocation('Vente du bien suite à mutation professionnelle'),

  death('Décès de l\'emprunteur ou de son conjoint'),

  forcedJobLoss('Cessation forcée de l\'activité professionnelle');

  final String label;

  const EarlyRepaymentExemption(this.label);

  bool get exempts => this != EarlyRepaymentExemption.none;
}
