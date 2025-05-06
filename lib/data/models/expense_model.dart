import 'package:isar/isar.dart';
import 'package:mybudget/domain/entities/expense.dart';

part 'expense_model.g.dart';

@collection
class ExpenseModel implements Expense {
  @override
  Id id = Isar.autoIncrement;
  
  @override
  @Index(type: IndexType.value)
  late String name;
  
  @override
  late double amount;
  
  @override
  late int categoryId;
  
  @override
  @Index()
  late DateTime date;
  
  @override
  late String frequency;
  
  @override
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
    final model = ExpenseModel()
      ..id = this.id
      ..name = name ?? this.name
      ..amount = amount ?? this.amount
      ..categoryId = categoryId ?? this.categoryId
      ..date = date ?? this.date
      ..frequency = frequency ?? this.frequency
      ..accountId = accountId ?? this.accountId;
    return model;
  }

  @override
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
    final model = ExpenseModel()
      ..name = json['name'] ?? ''
      ..amount = (json['amount'] ?? 0.0).toDouble()
      ..date = json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now()
      ..frequency = json['frequency'] ?? ''
      ..categoryId = json['categoryId'] != null 
          ? int.parse(json['categoryId'].toString()) 
          : 0
      ..accountId = json['accountId'] != null 
          ? int.parse(json['accountId'].toString()) 
          : 0;
    
    if (json['id'] != null) {
      model.id = int.parse(json['id'].toString());
    }
    
    return model;
  }
}
