import 'package:hive/hive.dart';
import 'package:mybudget/domain/entities/expense.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 0)
class ExpenseModel extends Expense {
  @HiveField(0)
  @override
  final String id;
  @HiveField(1)
  @override
  final String name;
  @HiveField(2)
  @override
  final double amount;
  @HiveField(3)
  @override
  final String category;
  @HiveField(4)
  @override
  final DateTime date;
  @HiveField(5)
  @override
  final String frequency;
  @HiveField(6)
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
