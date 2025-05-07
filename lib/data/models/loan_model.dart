import 'package:flutter/material.dart';
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
          : Colors.amber.shade700; // Ambre pour "à commencer" (attention/attente)
      case LoanStatus.partiallyPaid:
        return Theme.of(context).brightness == Brightness.dark
          ? Colors.blue.shade300
          : Colors.blue.shade600; // Bleu pour "en cours" (progression/activité)
      case LoanStatus.completed:
        return Theme.of(context).brightness == Brightness.dark
          ? Colors.green.shade300
          : Colors.green.shade600; // Vert pour "remboursé" (succès/terminé)
    }
  }
}

@Entity()
class LoanModel {
  @Id()
  int id = 0; // 0 signifie auto-increment dans ObjectBox

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

  double get paidAmount => getAutomaticPaidAmount();

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
