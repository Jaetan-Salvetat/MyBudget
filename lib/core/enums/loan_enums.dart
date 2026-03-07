enum LoanType { bank, personal }

enum LoanInsuranceType {
  fixed,
  percentage,
  none;

  String get label {
    switch (this) {
      case LoanInsuranceType.fixed:
        return 'Fixe';
      case LoanInsuranceType.percentage:
        return 'Pourcentage';
      case LoanInsuranceType.none:
        return 'Aucune';
    }
  }
}
