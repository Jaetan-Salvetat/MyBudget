import 'package:mybudget/domain/entities/revenue.dart';

class RevenueModel extends Revenue {
  @override
  final String id;
  @override
  final String name;
  @override
  final String accountId;
  @override
  final double amount;
  @override
  final bool isRegular;
  @override
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
