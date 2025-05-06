import 'package:isar/isar.dart';
import 'package:mybudget/domain/entities/revenue.dart';

part 'revenue_model.g.dart';

@collection
class RevenueModel implements Revenue {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(type: IndexType.value)
  late String name;

  @override
  late int accountId;

  @override
  late double amount;

  @override
  late bool isRegular;

  @override
  @Index()
  late DateTime date;

  RevenueModel();

  RevenueModel.create({
    required this.name,
    required this.amount,
    required this.isRegular,
    required this.date,
    required this.accountId,
  });

  factory RevenueModel.fromJson(Map<String, dynamic> json) {
    final model =
        RevenueModel()
          ..name = json['name'] ?? ''
          ..amount = (json['amount'] ?? 0.0).toDouble()
          ..isRegular = json['isRegular'] ?? false
          ..date =
              json['date'] != null
                  ? DateTime.parse(json['date'])
                  : DateTime.now()
          ..accountId =
              json['accountId'] != null
                  ? int.parse(json['accountId'].toString())
                  : 0;

    if (json['id'] != null) {
      model.id = int.parse(json['id'].toString());
    }

    return model;
  }

  RevenueModel copyWith({
    String? name,
    double? amount,
    bool? isRegular,
    DateTime? date,
    int? accountId,
  }) {
    final model =
        RevenueModel()
          ..id = id
          ..name = name ?? this.name
          ..amount = amount ?? this.amount
          ..isRegular = isRegular ?? this.isRegular
          ..date = date ?? this.date
          ..accountId = accountId ?? this.accountId;
    return model;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'name': name,
      'amount': amount,
      'isRegular': isRegular,
      'date': date.toIso8601String(),
      'accountId': accountId.toString(),
    };
  }
}
