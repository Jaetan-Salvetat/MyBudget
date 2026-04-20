import 'package:mybudget/core/enums/frequency.dart';
import 'package:objectbox/objectbox.dart';

const _sentinel = Object();

@Entity()
class RevenueModel {
  @Id()
  int id = 0;

  @Index()
  late String name;

  late int accountId;

  late double amount;

  @Property()
  late DateTime date;

  late String frequency;

  int? beneficiaryId;

  RevenueModel() {
    frequency = Frequency.monthly.label;
  }

  RevenueModel.create({
    required this.name,
    required this.amount,
    required this.date,
    required this.accountId,
    required this.frequency,
    this.beneficiaryId,
  });

  Frequency get frequencyEnum => Frequency.fromString(frequency);

  set frequencyEnum(Frequency value) {
    frequency = value.label;
  }

  factory RevenueModel.fromJson(Map<String, dynamic> json) {
    final model =
        RevenueModel()
          ..name = json['name'] ?? ''
          ..amount = (json['amount'] ?? 0.0).toDouble()
          ..date =
              json['date'] != null
                  ? (DateTime.tryParse(json['date'].toString()) ?? DateTime.now())
                  : DateTime.now()
          ..accountId =
              json['accountId'] != null
                  ? (int.tryParse(json['accountId'].toString()) ?? 0)
                  : 0
          ..frequency = json['frequency'] ?? Frequency.monthly.label
          ..beneficiaryId =
              json['beneficiaryId'] != null
                  ? int.tryParse(json['beneficiaryId'].toString())
                  : null;

    if (json['id'] != null) {
      model.id = int.tryParse(json['id'].toString()) ?? 0;
    }

    return model;
  }

  RevenueModel copyWith({
    String? name,
    double? amount,
    DateTime? date,
    int? accountId,
    String? frequency,
    Object? beneficiaryId = _sentinel,
  }) {
    final model =
        RevenueModel()
          ..id = id
          ..name = name ?? this.name
          ..amount = amount ?? this.amount
          ..date = date ?? this.date
          ..accountId = accountId ?? this.accountId
          ..frequency = frequency ?? this.frequency
          ..beneficiaryId =
              beneficiaryId == _sentinel
                  ? this.beneficiaryId
                  : beneficiaryId as int?;
    return model;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'name': name,
      'amount': amount,
      'date': date.toIso8601String(),
      'accountId': accountId.toString(),
      'frequency': frequency,
      'beneficiaryId': beneficiaryId?.toString(),
    };
  }
}
