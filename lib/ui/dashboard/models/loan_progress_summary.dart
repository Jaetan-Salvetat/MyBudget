class LoanProgressSummary {
  final double totalBorrowed;
  final double totalRepaid;
  final double totalRemaining;
  final double monthlyPayments;
  final int activeCount;
  final double progressPercent;

  const LoanProgressSummary({
    required this.totalBorrowed,
    required this.totalRepaid,
    required this.totalRemaining,
    required this.monthlyPayments,
    required this.activeCount,
    required this.progressPercent,
  });

  bool get hasLoans => activeCount > 0;
}
