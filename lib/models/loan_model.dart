import 'package:flutter/material.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';
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

/// Modèle de données pour un prêt (Data Transfer Object)
/// Responsabilité unique : stocker et sérialiser les données
/// La logique métier est déléguée aux services de calcul
@Entity()
class LoanModel {
  @Id()
  int id = 0;

  // Informations de base
  String name;
  double amount;
  String lenderName;
  int accountId;
  String? notes;

  // Dates et échéances
  int dayOfMonth;

  @Property()
  DateTime startDate;

  @Property()
  DateTime endDate;

  // Conditions financières
  double interestRate;
  int duration;

  // Type de remboursement (NOUVEAU)
  String repaymentTypeId;

  // Période de différé en mois (NOUVEAU)
  int deferredMonths;

  // Assurance
  String insuranceTypeId;
  double insuranceValue;
  String insuranceCalculationModeId; // NOUVEAU

  // Getters pour les enums (conversion uniquement, pas de logique)

  LoanRepaymentType get repaymentType {
    return LoanRepaymentType.values.firstWhere(
      (e) => e.name == repaymentTypeId,
      orElse: () => LoanRepaymentType.amortizable,
    );
  }

  set repaymentType(LoanRepaymentType type) {
    repaymentTypeId = type.name;
  }

  InsuranceCalculationMode get insuranceCalculationMode {
    return InsuranceCalculationMode.values.firstWhere(
      (e) => e.name == insuranceCalculationModeId,
      orElse: () => InsuranceCalculationMode.initialCapital,
    );
  }

  set insuranceCalculationMode(InsuranceCalculationMode mode) {
    insuranceCalculationModeId = mode.name;
  }

  LoanInsuranceType get insuranceType {
    return LoanInsuranceType.values.firstWhere(
      (e) => e.name == insuranceTypeId,
      orElse: () => LoanInsuranceType.none,
    );
  }

  set insuranceType(LoanInsuranceType type) {
    insuranceTypeId = type.name;
  }

  // Constructeur
  LoanModel({
    this.id = 0,
    required this.name,
    required this.amount,
    required this.lenderName,
    required this.accountId,
    required this.dayOfMonth,
    required this.startDate,
    required this.endDate,
    required this.interestRate,
    required this.duration,
    this.repaymentTypeId = 'amortizable',
    this.deferredMonths = 0,
    this.insuranceTypeId = 'none',
    this.insuranceValue = 0.0,
    this.insuranceCalculationModeId = 'initialCapital',
    this.notes,
  });

  /// Factory pour créer un prêt avec des paramètres nommés
  static LoanModel create({
    required String name,
    required double amount,
    required String lenderName,
    required int accountId,
    required int dayOfMonth,
    required DateTime startDate,
    required DateTime endDate,
    required double interestRate,
    required int duration,
    LoanRepaymentType repaymentType = LoanRepaymentType.amortizable,
    int deferredMonths = 0,
    LoanInsuranceType insuranceType = LoanInsuranceType.none,
    double insuranceValue = 0.0,
    InsuranceCalculationMode insuranceCalculationMode =
        InsuranceCalculationMode.initialCapital,
    String? notes,
  }) {
    return LoanModel(
      name: name,
      amount: amount,
      lenderName: lenderName,
      accountId: accountId,
      dayOfMonth: dayOfMonth,
      startDate: startDate,
      endDate: endDate,
      interestRate: interestRate,
      duration: duration,
      repaymentTypeId: repaymentType.name,
      deferredMonths: deferredMonths,
      insuranceTypeId: insuranceType.name,
      insuranceValue: insuranceValue,
      insuranceCalculationModeId: insuranceCalculationMode.name,
      notes: notes,
    );
  }

  /// Copie avec modifications
  LoanModel copyWith({
    String? name,
    double? amount,
    String? lenderName,
    int? accountId,
    int? dayOfMonth,
    DateTime? startDate,
    DateTime? endDate,
    double? interestRate,
    int? duration,
    LoanRepaymentType? repaymentType,
    int? deferredMonths,
    LoanInsuranceType? insuranceType,
    double? insuranceValue,
    InsuranceCalculationMode? insuranceCalculationMode,
    String? notes,
  }) {
    return LoanModel(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      lenderName: lenderName ?? this.lenderName,
      accountId: accountId ?? this.accountId,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      interestRate: interestRate ?? this.interestRate,
      duration: duration ?? this.duration,
      repaymentTypeId: repaymentType?.name ?? repaymentTypeId,
      deferredMonths: deferredMonths ?? this.deferredMonths,
      insuranceTypeId: insuranceType?.name ?? insuranceTypeId,
      insuranceValue: insuranceValue ?? this.insuranceValue,
      insuranceCalculationModeId:
          insuranceCalculationMode?.name ?? insuranceCalculationModeId,
      notes: notes ?? this.notes,
    );
  }
}
