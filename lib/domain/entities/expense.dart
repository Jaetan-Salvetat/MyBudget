abstract class Expense {
  final String id;
  final String name;
  final double amount;
  final String category;
  final DateTime date;
  final String frequency;
  final String accountId;

  Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.date,
    required this.frequency,
    required this.accountId,
  });

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
}