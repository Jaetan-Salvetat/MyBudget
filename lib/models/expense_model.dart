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

  late int categoryId;

  @Property()
  late DateTime date;

  late String frequency;

  late int accountId;

  int? beneficiaryId;

  ExpenseModel();

  ExpenseModel.create({
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.frequency,
    required this.accountId,
    this.beneficiaryId,
  });

  ExpenseModel copyWith({
    String? name,
    double? amount,
    int? categoryId,
    DateTime? date,
    String? frequency,
    int? accountId,
    Object? beneficiaryId = _sentinel,
  }) {
    final model =
        ExpenseModel()
          ..id = id
          ..name = name ?? this.name
          ..amount = amount ?? this.amount
          ..categoryId = categoryId ?? this.categoryId
          ..date = date ?? this.date
          ..frequency = frequency ?? this.frequency
          ..accountId = accountId ?? this.accountId
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
      'categoryId': categoryId.toString(),
      'date': date.toIso8601String(),
      'frequency': frequency,
      'accountId': accountId.toString(),
      'beneficiaryId': beneficiaryId?.toString(),
    };
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    final model =
        ExpenseModel()
          ..name = json['name'] ?? ''
          ..amount = (json['amount'] ?? 0.0).toDouble()
          ..date =
              json['date'] != null
                  ? (DateTime.tryParse(json['date'].toString()) ?? DateTime.now())
                  : DateTime.now()
          ..frequency = json['frequency'] ?? ''
          ..categoryId =
              json['categoryId'] != null
                  ? (int.tryParse(json['categoryId'].toString()) ?? 0)
                  : 0
          ..accountId =
              json['accountId'] != null
                  ? (int.tryParse(json['accountId'].toString()) ?? 0)
                  : 0
          ..beneficiaryId =
              json['beneficiaryId'] != null
                  ? int.tryParse(json['beneficiaryId'].toString())
                  : null;

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
