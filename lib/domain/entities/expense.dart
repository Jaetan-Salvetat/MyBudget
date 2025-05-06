abstract class Expense {
  final int id;
  final String name;
  final double amount;
  final int categoryId;
  final DateTime date;
  final String frequency;
  final int accountId;

  Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.frequency,
    required this.accountId,
  });

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
}