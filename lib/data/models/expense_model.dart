import 'package:mybudget/domain/entities/expense.dart';

class ExpenseModel extends Expense {
  @override
  final String id;
  @override
  final String name;
  @override
  final double amount;
  @override
  final String category;
  @override
  final DateTime date;
  @override
  final String frequency;
  @override
  final String accountId;

  ExpenseModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.date,
    required this.frequency,
    required this.accountId,
  }) : super(
    id: id,
    name: name,
    amount: amount,
    category: category,
    date: date,
    frequency: frequency,
    accountId: accountId,
  );

  ExpenseModel copyWith({
    String? id,
    String? name,
    double? amount,
    String? category,
    DateTime? date,
    String? frequency,
    String? accountId,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      frequency: frequency ?? this.frequency,
      accountId: accountId ?? this.accountId,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'frequency': frequency,
      'accountId': accountId,
    };
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      name: json['name'],
      amount: json['amount'],
      category: json['category'],
      date: DateTime.parse(json['date']),
      frequency: json['frequency'],
      accountId: json['accountId'],
    );
  }
}
