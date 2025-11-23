import 'package:objectbox/objectbox.dart';
import 'package:mybudget/core/enums/frequency.dart';

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

  ExpenseModel();

  ExpenseModel.create({
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.frequency,
    required this.accountId,
  });

  ExpenseModel copyWith({
    String? name,
    double? amount,
    int? categoryId,
    DateTime? date,
    String? frequency,
    int? accountId,
  }) {
    final model =
        ExpenseModel()
          ..id = id
          ..name = name ?? this.name
          ..amount = amount ?? this.amount
          ..categoryId = categoryId ?? this.categoryId
          ..date = date ?? this.date
          ..frequency = frequency ?? this.frequency
          ..accountId = accountId ?? this.accountId;
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
    };
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    final model =
        ExpenseModel()
          ..name = json['name'] ?? ''
          ..amount = (json['amount'] ?? 0.0).toDouble()
          ..date =
              json['date'] != null
                  ? DateTime.parse(json['date'])
                  : DateTime.now()
          ..frequency = json['frequency'] ?? ''
          ..categoryId =
              json['categoryId'] != null
                  ? int.parse(json['categoryId'].toString())
                  : 0
          ..accountId =
              json['accountId'] != null
                  ? int.parse(json['accountId'].toString())
                  : 0;

    if (json['id'] != null) {
      model.id = int.parse(json['id'].toString());
    }

    return model;
  }

  Frequency get frequencyEnum => Frequency.fromString(frequency);

  set frequencyEnum(Frequency value) {
    frequency = value.label;
  }
}
