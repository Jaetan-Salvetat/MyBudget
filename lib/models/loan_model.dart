import 'package:flutter/material.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/utils/loan_calculator.dart';
import 'package:objectbox/objectbox.dart';

enum LoanStatus {
  pending('À commencer', Icons.schedule),
  partiallyPaid('En cours', Icons.pending_actions),
  completed('Remboursé', Icons.check_circle);

  final String label;
  final IconData icon;

  const LoanStatus(this.label, this.icon);

  Color getColor(BuildContext context) {
    switch (this) {
      case LoanStatus.pending:
        return Theme.of(context).brightness == Brightness.dark
            ? Colors.amber.shade300
            : Colors.amber.shade700;
      case LoanStatus.partiallyPaid:
        return Theme.of(context).brightness == Brightness.dark
            ? Colors.blue.shade300
            : Colors.blue.shade600;
      case LoanStatus.completed:
        return Theme.of(context).brightness == Brightness.dark
            ? Colors.green.shade300
            : Colors.green.shade600;
    }
  }
}

@Entity()
class LoanModel {
  @Id()
  int id = 0;

  String name;
  double amount;
  String lenderName;

  int dayOfMonth;

  @Property()
  DateTime startDate;

  @Property()
  DateTime endDate;

  double monthlyPayment;

  int accountId;
  String? notes;

  double interestRate;
  int duration;

  String insuranceTypeId;
  double insuranceValue;

  double get paidAmount => totalPaidCash;

  LoanInsuranceType get insuranceType {
    return LoanInsuranceType.values.firstWhere(
      (e) => e.name == insuranceTypeId,
      orElse: () => LoanInsuranceType.none,
    );
  }

  set insuranceType(LoanInsuranceType type) {
    insuranceTypeId = type.name;
  }

  LoanModel({
    this.id = 0,
    required this.name,
    required this.amount,
    required this.lenderName,
    required this.dayOfMonth,
    required this.startDate,
    required this.endDate,
    required this.accountId,
    required this.monthlyPayment,
    this.notes,
    this.interestRate = 0.0,
    this.duration = 0,
    this.insuranceTypeId = 'none',
    this.insuranceValue = 0.0,
  });

  static LoanModel create({
    required String name,
    required double amount,
    required String lenderName,
    required int dayOfMonth,
    required DateTime startDate,
    required DateTime endDate,
    required int accountId,
    required double monthlyPayment,
    String? notes,
    double interestRate = 0.0,
    int duration = 0,
    LoanInsuranceType insuranceType = LoanInsuranceType.none,
    double insuranceValue = 0.0,
  }) {
    return LoanModel(
      name: name,
      amount: amount,
      lenderName: lenderName,
      dayOfMonth: dayOfMonth,
      startDate: startDate,
      endDate: endDate,
      accountId: accountId,
      monthlyPayment: monthlyPayment,
      notes: notes,
      interestRate: interestRate,
      duration: duration,
      insuranceTypeId: insuranceType.name,
      insuranceValue: insuranceValue,
    );
  }

  LoanModel copyWith({
    String? name,
    double? amount,
    String? lenderName,
    int? dayOfMonth,
    DateTime? startDate,
    DateTime? endDate,
    int? accountId,
    double? monthlyPayment,
    String? notes,
    double? interestRate,
    int? duration,
    LoanInsuranceType? insuranceType,
    double? insuranceValue,
  }) {
    return LoanModel(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      lenderName: lenderName ?? this.lenderName,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      accountId: accountId ?? this.accountId,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      notes: notes ?? this.notes,
      interestRate: interestRate ?? this.interestRate,
      duration: duration ?? this.duration,
      insuranceTypeId: insuranceType?.name ?? this.insuranceTypeId,
      insuranceValue: insuranceValue ?? this.insuranceValue,
    );
  }

  double get remainingCapital {
    final now = DateTime.now();

    if (now.isBefore(startDate)) {
      return amount;
    }

    if (now.isAfter(endDate)) {
      return 0.0;
    }

    final startYearMonth = startDate.year * 12 + startDate.month - 1;
    final nowYearMonth = now.year * 12 + now.month - 1;
    final daysPassed = now.day >= dayOfMonth ? 1 : 0;

    final monthsPassed = (nowYearMonth - startYearMonth) + daysPassed;

    if (duration == 0) {
      final paidNaive = monthsPassed * monthlyPayment;
      return (amount - paidNaive).clamp(0.0, amount);
    }

    return LoanCalculator.calculateRemainingPrincipal(
      amount: amount,
      annualRate: interestRate,
      durationInMonths: duration,
      monthsPassed: monthsPassed,
    );
  }

  int get remainingMonths {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;

    final realDuration =
        duration > 0
            ? duration
            : (endDate.year - startDate.year) * 12 +
                endDate.month -
                startDate.month;

    if (now.isBefore(startDate)) return realDuration;

    final endYearMonth = endDate.year * 12 + endDate.month;
    final nowYearMonth = now.year * 12 + now.month;

    final diff = endYearMonth - nowYearMonth;
    return diff.clamp(0, realDuration);
  }

  double getRemainingAmount() {
    return remainingCapital;
  }

  double getProgressPercentage() {
    if (amount == 0) return 0.0;
    final remaining = remainingCapital;
    return (amount - remaining) / amount;
  }

  bool isCompleted() {
    return getAutomaticStatus() == LoanStatus.completed;
  }

  LoanStatus getAutomaticStatus() {
    final now = DateTime.now();

    if (now.isAfter(endDate)) {
      return LoanStatus.completed;
    }

    if (remainingCapital <= 0) {
      return LoanStatus.completed;
    }

    if (now.isBefore(startDate)) {
      return LoanStatus.pending;
    }

    return LoanStatus.partiallyPaid;
  }

  double get totalPaidCash => getAutomaticPaidAmount();

  double getAutomaticPaidAmount() {
    final now = DateTime.now();

    if (now.isBefore(startDate)) {
      return 0.0;
    }

    final effectiveEndDate = now.isAfter(endDate) ? endDate : now;

    final startYearMonth = startDate.year * 12 + startDate.month - 1;
    final endYearMonth =
        effectiveEndDate.year * 12 + effectiveEndDate.month - 1;
    final daysPassed = effectiveEndDate.day >= dayOfMonth ? 1 : 0;

    final monthsPassed = (endYearMonth - startYearMonth) + daysPassed;

    return monthsPassed * monthlyPayment;
  }
}
