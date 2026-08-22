class LoanProgressEntry {
  final int id;
  final String name;
  final double remainingCapital;
  final double monthlyPayment;
  final int remainingMonths;

  const LoanProgressEntry({
    required this.id,
    required this.name,
    required this.remainingCapital,
    required this.monthlyPayment,
    required this.remainingMonths,
  });
}

class LoanProgressSummary {
  final double totalBorrowed;
  final double totalRepaid;
  final double totalRemaining;
  final double monthlyPayments;
  final int activeCount;
  final double progressPercent;
  final List<LoanProgressEntry> loans;

  const LoanProgressSummary({
    required this.totalBorrowed,
    required this.totalRepaid,
    required this.totalRemaining,
    required this.monthlyPayments,
    required this.activeCount,
    required this.progressPercent,
    this.loans = const [],
  });

  bool get hasLoans => activeCount > 0;
}
