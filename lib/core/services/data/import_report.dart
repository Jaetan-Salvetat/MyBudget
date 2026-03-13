import 'package:mybudget/core/services/data/import_entity_report.dart';

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
