import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:objectbox/objectbox.dart';

enum LoanStatus {
  pending('À commencer', Symbols.schedule_rounded),
  partiallyPaid('En cours', Symbols.pending_actions_rounded),
  completed('Remboursé', Symbols.check_circle_rounded);

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
  int accountId;
  String? notes;

  int dayOfMonth;

  @Property()
  DateTime startDate;

  @Property()
  DateTime endDate;

  double interestRate;
  int duration;

  String repaymentTypeId;

  int deferredMonths;

  String insuranceTypeId;
  double insuranceValue;
  String insuranceCalculationModeId;

  bool immediateFirstPayment;

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
    this.immediateFirstPayment = false,
    this.notes,
  });

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
    bool immediateFirstPayment = false,
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
      immediateFirstPayment: immediateFirstPayment,
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'name': name,
      'amount': amount,
      'accountId': accountId.toString(),
      'lenderName': lenderName,
      'dayOfMonth': dayOfMonth,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'interestRate': interestRate,
      'duration': duration,
      'repaymentTypeId': repaymentTypeId,
      'deferredMonths': deferredMonths,
      'insuranceTypeId': insuranceTypeId,
      'insuranceValue': insuranceValue,
      'insuranceCalculationModeId': insuranceCalculationModeId,
      'immediateFirstPayment': immediateFirstPayment,
      'notes': notes,
    };
  }

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    dynamic resolve(String camelKey, String snakeKey) {
      return json[camelKey] ?? json[snakeKey];
    }

    return LoanModel(
      id: json['id'] != null ? (int.tryParse(json['id'].toString()) ?? 0) : 0,
      name: (resolve('name', 'name') as String?) ?? '',
      amount: (resolve('amount', 'amount') as num?)?.toDouble() ?? 0.0,
      accountId:
          int.tryParse(
            (resolve('accountId', 'account_id') ?? '0').toString(),
          ) ??
          0,
      lenderName:
          (resolve('lenderName', 'lender_name') as String?) ?? 'Non spécifié',
      dayOfMonth: (resolve('dayOfMonth', 'day_of_month') as int?) ?? 1,
      startDate:
          DateTime.tryParse(
            (resolve('startDate', 'start_date') ?? '').toString(),
          ) ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(
            (resolve('endDate', 'end_date') ?? '').toString(),
          ) ??
          DateTime.now().add(const Duration(days: 365)),
      interestRate:
          (resolve('interestRate', 'interest_rate') as num?)?.toDouble() ?? 0.0,
      duration: (resolve('duration', 'duration') as int?) ?? 0,
      repaymentTypeId:
          (resolve('repaymentTypeId', 'repayment_type_id') as String?) ??
          'amortizable',
      deferredMonths:
          (resolve('deferredMonths', 'deferred_months') as int?) ?? 0,
      insuranceTypeId:
          (resolve('insuranceTypeId', 'insurance_type_id') as String?) ??
          'none',
      insuranceValue:
          (resolve('insuranceValue', 'insurance_value') as num?)?.toDouble() ??
          0.0,
      insuranceCalculationModeId:
          (resolve(
                'insuranceCalculationModeId',
                'insurance_calculation_mode_id',
              )
              as String?) ??
          'initialCapital',
      immediateFirstPayment:
          (resolve('immediateFirstPayment', 'immediate_first_payment')
              as bool?) ??
          false,
      notes: json['notes'] as String?,
    );
  }

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
    bool? immediateFirstPayment,
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
      immediateFirstPayment:
          immediateFirstPayment ?? this.immediateFirstPayment,
      notes: notes ?? this.notes,
    );
  }
}
