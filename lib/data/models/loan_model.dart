import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

part 'loan_model.g.dart';

enum LoanStatus {
  pending('À commencer', Icons.schedule),
  partiallyPaid('En cours', Icons.pending_actions),
  completed('Remboursé', Icons.check_circle);
  
  final String label;
  final IconData icon;
  
  const LoanStatus(this.label, this.icon);
  
  Color getColor(BuildContext context) {
    switch(this) {
      case LoanStatus.pending:
        return Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
      case LoanStatus.partiallyPaid:
        return Theme.of(context).colorScheme.primary;
      case LoanStatus.completed:
        return Theme.of(context).colorScheme.secondary;
    }
  }
}

@collection
class LoanModel {
  Id id = Isar.autoIncrement;

  String name;
  double amount;
  String lenderName;
  
  int dayOfMonth;
  DateTime startDate;
  DateTime endDate;
  
  double monthlyPayment;
  
  int accountId;
  double paidAmount = 0.0;
  String? notes;

  LoanModel({
    this.id = Isar.autoIncrement,
    required this.name,
    required this.amount,
    required this.lenderName,
    required this.dayOfMonth,
    required this.startDate,
    required this.endDate,
    required this.accountId,
    required this.monthlyPayment,
    this.paidAmount = 0.0,
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
    double? paidAmount,
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
      paidAmount: paidAmount ?? this.paidAmount,
      notes: notes ?? this.notes,
    );
  }

  double getRemainingAmount() {
    return amount - paidAmount;
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
