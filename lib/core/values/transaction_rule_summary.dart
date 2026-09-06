class TransactionRuleSummary {
  const TransactionRuleSummary({
    required this.occurrences,
    required this.totalToDate,
    required this.since,
    required this.nextDueDate,
    required this.annualImpact,
  });
  final int occurrences;
  final double totalToDate;
  final DateTime since;
  final DateTime? nextDueDate;
  final double? annualImpact;
}
