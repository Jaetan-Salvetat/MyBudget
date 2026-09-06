class EarlyRepaymentQuote {
  const EarlyRepaymentQuote({
    required this.settlementDate,
    required this.remainingCapitalBefore,
    required this.repaidCapital,
    required this.indemnity,
    required this.settlementPayment,
    required this.costSaved,
    required this.monthsSaved,
    required this.newMonthlyPayment,
    required this.newEndDate,
    required this.isBelowBankMinimum,
  });
  final DateTime settlementDate;
  final double remainingCapitalBefore;
  final double repaidCapital;
  final double indemnity;
  final double settlementPayment;
  final double costSaved;
  final int monthsSaved;
  final double newMonthlyPayment;
  final DateTime? newEndDate;
  final bool isBelowBankMinimum;

  double get totalDue => settlementPayment + repaidCapital + indemnity;

  bool get clearsTheLoan => newEndDate == null || newMonthlyPayment == 0;
}
