import 'package:mybudget/core/entities/loan_event.dart';
import 'package:mybudget/core/enums/loan_event_types.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class LoanEventModel {
  @Id()
  int id = 0;

  int loanId;

  String typeId;

  @Property()
  DateTime date;

  double amount;

  String reamortizationModeId;

  String exemptionId;

  LoanEventType get type => LoanEventType.values.firstWhere(
    (e) => e.name == typeId,
    orElse: () => LoanEventType.earlyRepaymentPartial,
  );

  set type(LoanEventType value) => typeId = value.name;

  ReamortizationMode get reamortizationMode =>
      ReamortizationMode.values.firstWhere(
        (e) => e.name == reamortizationModeId,
        orElse: () => ReamortizationMode.reduceDuration,
      );

  set reamortizationMode(ReamortizationMode value) =>
      reamortizationModeId = value.name;

  EarlyRepaymentExemption get exemption =>
      EarlyRepaymentExemption.values.firstWhere(
        (e) => e.name == exemptionId,
        orElse: () => EarlyRepaymentExemption.none,
      );

  set exemption(EarlyRepaymentExemption value) => exemptionId = value.name;

  LoanEventModel({
    this.id = 0,
    required this.loanId,
    required this.date,
    this.typeId = 'earlyRepaymentPartial',
    this.amount = 0.0,
    this.reamortizationModeId = 'reduceDuration',
    this.exemptionId = 'none',
  });

  static LoanEventModel create({
    required int loanId,
    required LoanEventType type,
    required DateTime date,
    double amount = 0.0,
    ReamortizationMode reamortizationMode = ReamortizationMode.reduceDuration,
    EarlyRepaymentExemption exemption = EarlyRepaymentExemption.none,
  }) {
    return LoanEventModel(
      loanId: loanId,
      typeId: type.name,
      date: date,
      amount: amount,
      reamortizationModeId: reamortizationMode.name,
      exemptionId: exemption.name,
    );
  }

  LoanEvent toEntity() => LoanEvent(
    id: id,
    type: type,
    date: date,
    amount: amount,
    reamortizationMode: reamortizationMode,
    exemption: exemption,
  );

  LoanEventModel copyWith({
    int? loanId,
    LoanEventType? type,
    DateTime? date,
    double? amount,
    ReamortizationMode? reamortizationMode,
    EarlyRepaymentExemption? exemption,
  }) {
    return LoanEventModel(
      id: id,
      loanId: loanId ?? this.loanId,
      typeId: type?.name ?? typeId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      reamortizationModeId:
          reamortizationMode?.name ?? reamortizationModeId,
      exemptionId: exemption?.name ?? exemptionId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id.toString(),
    'loanId': loanId.toString(),
    'typeId': typeId,
    'date': date.toIso8601String(),
    'amount': amount,
    'reamortizationModeId': reamortizationModeId,
    'exemptionId': exemptionId,
  };

  factory LoanEventModel.fromJson(Map<String, dynamic> json) {
    dynamic resolve(String camelKey, String snakeKey) =>
        json[camelKey] ?? json[snakeKey];

    return LoanEventModel(
      id: int.tryParse((json['id'] ?? '0').toString()) ?? 0,
      loanId: int.tryParse((resolve('loanId', 'loan_id') ?? '0').toString()) ?? 0,
      typeId:
          (resolve('typeId', 'type_id') as String?) ?? 'earlyRepaymentPartial',
      date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      reamortizationModeId:
          (resolve('reamortizationModeId', 'reamortization_mode_id')
              as String?) ??
          'reduceDuration',
      exemptionId: (resolve('exemptionId', 'exemption_id') as String?) ?? 'none',
    );
  }
}
