class ImportEntityReport {
  final String entityName;
  final int total;
  final int imported;
  final int skipped;
  final List<String> errors;

  const ImportEntityReport({
    required this.entityName,
    this.total = 0,
    this.imported = 0,
    this.skipped = 0,
    this.errors = const [],
  });

  bool get hasIssues => skipped > 0 || errors.isNotEmpty;
}

class ImportReport {
  final ImportEntityReport beneficiaries;
  final ImportEntityReport accounts;
  final ImportEntityReport categories;
  final ImportEntityReport expenses;
  final ImportEntityReport revenues;
  final ImportEntityReport loans;
  final ImportEntityReport transfers;

  const ImportReport({
    this.beneficiaries = const ImportEntityReport(entityName: 'Bénéficiaires'),
    this.accounts = const ImportEntityReport(entityName: 'Comptes'),
    this.categories = const ImportEntityReport(entityName: 'Catégories'),
    this.expenses = const ImportEntityReport(entityName: 'Dépenses'),
    this.revenues = const ImportEntityReport(entityName: 'Revenus'),
    this.loans = const ImportEntityReport(entityName: 'Emprunts'),
    this.transfers = const ImportEntityReport(entityName: 'Virements'),
  });

  List<ImportEntityReport> get all =>
      [beneficiaries, accounts, categories, expenses, revenues, loans, transfers];

  bool get hasWarnings => all.any((r) => r.hasIssues);

  int get totalImported => all.fold(0, (sum, r) => sum + r.imported);

  int get totalSkipped => all.fold(0, (sum, r) => sum + r.skipped);
}
