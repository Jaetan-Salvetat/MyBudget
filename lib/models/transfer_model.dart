import 'package:objectbox/objectbox.dart';
import 'package:mybudget/core/enums/frequency.dart';

const _sentinel = Object();

@Entity()
class TransferModel {
  @Id()
  int id = 0;

  @Index()
  late String name;

  late double amount;

  late int fromAccountId;

  late int toAccountId;

  @Property(uid: 1221948770519669890)
  late DateTime startDate;

  @Property()
  DateTime? endDate;

  int? parentId;

  late String frequency;

  TransferModel();

  TransferModel.create({
    required this.name,
    required this.amount,
    required this.fromAccountId,
    required this.toAccountId,
    required this.startDate,
    required this.frequency,
    this.endDate,
    this.parentId,
  });

  TransferModel copyWith({
    String? name,
    double? amount,
    int? fromAccountId,
    int? toAccountId,
    DateTime? startDate,
    String? frequency,
    Object? endDate = _sentinel,
    Object? parentId = _sentinel,
  }) {
    final model = TransferModel()
      ..id = id
      ..name = name ?? this.name
      ..amount = amount ?? this.amount
      ..fromAccountId = fromAccountId ?? this.fromAccountId
      ..toAccountId = toAccountId ?? this.toAccountId
      ..startDate = startDate ?? this.startDate
      ..frequency = frequency ?? this.frequency
      ..endDate = endDate == _sentinel ? this.endDate : endDate as DateTime?
      ..parentId = parentId == _sentinel ? this.parentId : parentId as int?;
    return model;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'name': name,
      'amount': amount,
      'fromAccountId': fromAccountId.toString(),
      'toAccountId': toAccountId.toString(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'parentId': parentId?.toString(),
      'frequency': frequency,
    };
  }

  factory TransferModel.fromJson(Map<String, dynamic> json) {
    final dateStr = json['startDate'] ?? json['date'];
    final model = TransferModel()
      ..name = json['name'] ?? ''
      ..amount = (json['amount'] ?? 0.0).toDouble()
      ..startDate = dateStr != null
          ? (DateTime.tryParse(dateStr.toString()) ?? DateTime.now())
          : DateTime.now()
      ..endDate = json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null
      ..parentId = json['parentId'] != null
          ? int.tryParse(json['parentId'].toString())
          : null
      ..frequency = json['frequency'] ?? ''
      ..fromAccountId = json['fromAccountId'] != null
          ? (int.tryParse(json['fromAccountId'].toString()) ?? 0)
          : 0
      ..toAccountId = json['toAccountId'] != null
          ? (int.tryParse(json['toAccountId'].toString()) ?? 0)
          : 0;

    if (json['id'] != null) {
      model.id = int.tryParse(json['id'].toString()) ?? 0;
    }

    return model;
  }

  Frequency get frequencyEnum => Frequency.fromString(frequency);

  set frequencyEnum(Frequency value) {
    frequency = value.label;
  }
}
