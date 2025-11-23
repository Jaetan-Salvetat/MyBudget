import 'package:flutter/material.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
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

  // Nouveaux champs pour le calcul précis
  double interestRate; // Taux annuel en %
  int duration; // Durée en mois

  // Stockage de l'enum en int pour ObjectBox
  int insuranceTypeIndex;
  double insuranceValue; // Valeur de l'assurance (Montant ou %)

  double get paidAmount => getAutomaticPaidAmount();

  // Helper pour l'enum InsuranceType
  LoanInsuranceType get insuranceType {
    if (insuranceTypeIndex >= 0 &&
        insuranceTypeIndex < LoanInsuranceType.values.length) {
      return LoanInsuranceType.values[insuranceTypeIndex];
    }
    return LoanInsuranceType.none;
  }

  set insuranceType(LoanInsuranceType type) {
    insuranceTypeIndex = type.index;
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
    this.insuranceTypeIndex = 0, // Default to none
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
      insuranceTypeIndex: insuranceType.index,
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
      insuranceTypeIndex: insuranceType?.index ?? this.insuranceTypeIndex,
      insuranceValue: insuranceValue ?? this.insuranceValue,
    );
  }

  double getRemainingAmount() {
    return amount - getAutomaticPaidAmount();
  }

  double getProgressPercentage() {
    return getAutomaticPaidAmount() / amount;
  }

  bool isCompleted() {
    return getAutomaticStatus() == LoanStatus.completed;
  }

  LoanStatus getAutomaticStatus() {
    final paidAmount = getAutomaticPaidAmount();

    if (paidAmount >= amount) {
      return LoanStatus.completed;
    }

    final now = DateTime.now();

    if (now.isBefore(startDate)) {
      return LoanStatus.pending;
    }

    if (paidAmount > 0) {
      return LoanStatus.partiallyPaid;
    }

    return LoanStatus.pending;
  }

  double getAutomaticPaidAmount() {
    final now = DateTime.now();

    if (now.isBefore(startDate)) {
      return 0.0;
    }

    if (now.isAfter(endDate)) {
      return amount;
    }

    final startYearMonth = startDate.year * 12 + startDate.month - 1;
    final nowYearMonth = now.year * 12 + now.month - 1;
    final daysPassed = now.day >= dayOfMonth ? 1 : 0;

    final monthsPassed = (nowYearMonth - startYearMonth) + daysPassed;
    final automaticPaidAmount = monthsPassed * monthlyPayment;

    return automaticPaidAmount > amount ? amount : automaticPaidAmount;
  }
}
