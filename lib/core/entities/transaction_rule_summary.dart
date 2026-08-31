class TransactionRuleSummary {
  final int occurrences;
  final double totalToDate;
  final DateTime since;
  final DateTime? nextDueDate;
  final double? annualImpact;

  const TransactionRuleSummary({
    required this.occurrences,
    required this.totalToDate,
    required this.since,
    required this.nextDueDate,
    required this.annualImpact,
  });
}
