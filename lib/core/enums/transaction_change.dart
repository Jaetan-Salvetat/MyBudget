enum TransactionChange {
  created,
  amount,
  name,
  frequency,
  account,
  beneficiary,
  category,
  closed;

  String get label {
    switch (this) {
      case TransactionChange.created:
        return 'Création';
      case TransactionChange.amount:
        return 'Montant';
      case TransactionChange.name:
        return 'Nom';
      case TransactionChange.frequency:
        return 'Fréquence';
      case TransactionChange.account:
        return 'Compte';
      case TransactionChange.beneficiary:
        return 'Bénéficiaire';
      case TransactionChange.category:
        return 'Catégorie';
      case TransactionChange.closed:
        return 'Clôture';
    }
  }

  static TransactionChange fromName(String value) {
    return TransactionChange.values.firstWhere(
      (change) => change.name == value,
      orElse: () => TransactionChange.created,
    );
  }
}
