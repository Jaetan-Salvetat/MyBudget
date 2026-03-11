class LoanPaymentBreakdown {
  final double capitalPayment;
  final double interestPayment;
  final double insurancePayment;
  final double totalPayment;

  const LoanPaymentBreakdown({
    required this.capitalPayment,
    required this.interestPayment,
    required this.insurancePayment,
    required this.totalPayment,
  });

  const LoanPaymentBreakdown.zero()
      : capitalPayment = 0.0,
        interestPayment = 0.0,
        insurancePayment = 0.0,
        totalPayment = 0.0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanPaymentBreakdown &&
          runtimeType == other.runtimeType &&
          capitalPayment == other.capitalPayment &&
          interestPayment == other.interestPayment &&
          insurancePayment == other.insurancePayment &&
          totalPayment == other.totalPayment;

  @override
  int get hashCode =>
      capitalPayment.hashCode ^
      interestPayment.hashCode ^
      insurancePayment.hashCode ^
      totalPayment.hashCode;
}
