import 'package:hive/hive.dart';
import 'package:mybudget/domain/entities/revenue.dart';

part 'revenue_model.g.dart';

@HiveType(typeId: 1)
class RevenueModel extends Revenue {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final double amount;
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
  }) :  super(
          id: id,
          name: name,
          amount: amount,
          isRegular: isRegular,
          date: date,
        );

  factory RevenueModel.fromJson(Map<String, dynamic> json) {
    return RevenueModel(
      id: json['id'],
      name: json['name'],
      amount: json['amount'],
      isRegular: json['isRegular'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'isRegular': isRegular,
      'date': date.toIso8601String(),
    };
  }
}