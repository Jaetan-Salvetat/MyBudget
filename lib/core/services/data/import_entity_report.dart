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
