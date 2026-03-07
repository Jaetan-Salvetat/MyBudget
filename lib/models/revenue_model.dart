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

  late bool isRegular;

  @Property()
  late DateTime date;

  int? beneficiaryId;

  RevenueModel();

  RevenueModel.create({
    required this.name,
    required this.amount,
    required this.isRegular,
    required this.date,
    required this.accountId,
    this.beneficiaryId,
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
                  : 0
          ..beneficiaryId =
              json['beneficiaryId'] != null
                  ? int.tryParse(json['beneficiaryId'].toString())
                  : null;

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
    Object? beneficiaryId = _sentinel,
  }) {
    final model =
        RevenueModel()
          ..id = id
          ..name = name ?? this.name
          ..amount = amount ?? this.amount
          ..isRegular = isRegular ?? this.isRegular
          ..date = date ?? this.date
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
      'isRegular': isRegular,
      'date': date.toIso8601String(),
      'accountId': accountId.toString(),
      'beneficiaryId': beneficiaryId?.toString(),
    };
  }
}
