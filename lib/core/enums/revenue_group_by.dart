enum RevenueGroupBy {
  frequency,
  category,
  beneficiary,
  account,
  none;

  String get label => switch (this) {
    RevenueGroupBy.frequency => 'Fréquence',
    RevenueGroupBy.category => 'Catégorie',
    RevenueGroupBy.beneficiary => 'Bénéficiaire',
    RevenueGroupBy.account => 'Compte',
    RevenueGroupBy.none => 'Aucun',
  };

  static RevenueGroupBy fromName(String? value) {
    return RevenueGroupBy.values.firstWhere(
      (axis) => axis.name == value,
      orElse: () => RevenueGroupBy.frequency,
    );
  }
}
