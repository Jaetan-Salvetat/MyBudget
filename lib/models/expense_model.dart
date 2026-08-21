import 'package:objectbox/objectbox.dart';
import 'package:mybudget/core/enums/frequency.dart';

const _sentinel = Object();

@Entity()
class ExpenseModel {
  @Id()
  int id = 0;

  @Index()
  late String name;

  late double amount;

  @Index()
  String? categorySlug;

  @Property(uid: 7133072174613285923)
  late DateTime startDate;

  @Property()
  DateTime? endDate;

  int? parentId;

  late String frequency;

  late int accountId;

  int? beneficiaryId;

  String? receiptPath;

  ExpenseModel();

  ExpenseModel.create({
    required this.name,
    required this.amount,
    this.categorySlug,
    required this.startDate,
    required this.frequency,
    required this.accountId,
    this.endDate,
    this.parentId,
    this.beneficiaryId,
    this.receiptPath,
  });

  ExpenseModel copyWith({
    String? name,
    double? amount,
    String? categorySlug,
    DateTime? startDate,
    String? frequency,
    int? accountId,
    Object? endDate = _sentinel,
    Object? parentId = _sentinel,
    Object? beneficiaryId = _sentinel,
    Object? receiptPath = _sentinel,
  }) {
    final model =
        ExpenseModel()
          ..id = id
          ..name = name ?? this.name
          ..amount = amount ?? this.amount
          ..categorySlug = categorySlug ?? this.categorySlug
          ..startDate = startDate ?? this.startDate
          ..frequency = frequency ?? this.frequency
          ..accountId = accountId ?? this.accountId
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
                  : beneficiaryId as int?
          ..receiptPath =
              receiptPath == _sentinel
                  ? this.receiptPath
                  : receiptPath as String?;
    return model;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'name': name,
      'amount': amount,
      'categorySlug': categorySlug,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'parentId': parentId?.toString(),
      'frequency': frequency,
      'accountId': accountId.toString(),
      'beneficiaryId': beneficiaryId?.toString(),
      'receiptPath': receiptPath,
    };
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    final dateStr = json['startDate'] ?? json['date'];
    final model =
        ExpenseModel()
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
          ..frequency = json['frequency'] ?? ''
          ..categorySlug = json['categorySlug'] as String?
          ..accountId =
              json['accountId'] != null
                  ? (int.tryParse(json['accountId'].toString()) ?? 0)
                  : 0
          ..beneficiaryId =
              json['beneficiaryId'] != null
                  ? int.tryParse(json['beneficiaryId'].toString())
                  : null
          ..receiptPath = json['receiptPath'] as String?;

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
