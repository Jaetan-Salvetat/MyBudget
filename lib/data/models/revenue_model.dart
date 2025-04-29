import 'package:hive/hive.dart';
import 'package:mybudget/domain/entities/revenue.dart';

part 'revenue_model.g.dart';

@HiveType(typeId: 1)
class RevenueModel extends Revenue {
  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String name;
  @override
  @HiveField(6)
  final String accountId;
  @override
  @HiveField(2)
  final double amount;
  @override
  @HiveField(3)
  final bool isRegular;
  @override
  @HiveField(4)
  final DateTime date;

  RevenueModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.isRegular,
    required this.date,
    required this.accountId,
  }) : super(
         id: id,
         name: name,
         amount: amount,
         isRegular: isRegular,
         date: date,
         accountId: accountId,
       );

  factory RevenueModel.fromJson(Map<String, dynamic> json) {
    return RevenueModel(
      id: json['id'],
      name: json['name'],
      amount: json['amount'],
      isRegular: json['isRegular'],
      date: DateTime.parse(json['date']),
      accountId: json['accountId'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'isRegular': isRegular,
      'date': date.toIso8601String(),
      'accountId': accountId,
    };
  }
}
