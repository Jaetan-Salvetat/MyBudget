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

  @Property(uid: 1213904468792118615)
  late DateTime startDate;

  @Property()
  DateTime? endDate;

  int? parentId;

  late String frequency;

  int? beneficiaryId;

  RevenueModel() {
    frequency = Frequency.monthly.label;
  }

  RevenueModel.create({
    required this.name,
    required this.amount,
    required this.startDate,
    required this.accountId,
    required this.frequency,
    this.endDate,
    this.parentId,
    this.beneficiaryId,
  });

  Frequency get frequencyEnum => Frequency.fromString(frequency);

  set frequencyEnum(Frequency value) {
    frequency = value.label;
  }

  factory RevenueModel.fromJson(Map<String, dynamic> json) {
    final dateStr = json['startDate'] ?? json['date'];
    final model =
        RevenueModel()
          ..name = json['name'] ?? ''
          ..amount = (json['amount'] ?? 0.0).toDouble()
          ..startDate =
              dateStr != null
                  ? (DateTime.tryParse(dateStr.toString()) ?? DateTime.now())
                  : DateTime.now()
          ..endDate =
              json['endDate'] != null
                  ? DateTime.tryParse(json['endDate'].toString())
                  : null
          ..parentId =
              json['parentId'] != null
                  ? int.tryParse(json['parentId'].toString())
                  : null
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
    DateTime? startDate,
    int? accountId,
    String? frequency,
    Object? endDate = _sentinel,
    Object? parentId = _sentinel,
    Object? beneficiaryId = _sentinel,
  }) {
    final model =
        RevenueModel()
          ..id = id
          ..name = name ?? this.name
          ..amount = amount ?? this.amount
          ..startDate = startDate ?? this.startDate
          ..accountId = accountId ?? this.accountId
          ..frequency = frequency ?? this.frequency
          ..endDate =
              endDate == _sentinel
                  ? this.endDate
                  : endDate as DateTime?
          ..parentId =
              parentId == _sentinel
                  ? this.parentId
                  : parentId as int?
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
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'parentId': parentId?.toString(),
      'accountId': accountId.toString(),
      'frequency': frequency,
      'beneficiaryId': beneficiaryId?.toString(),
    };
  }
}
