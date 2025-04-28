class Expense {
  final String id;
  final String name;
  final double amount;
  final String category;
  final DateTime date;
  final String frequency;

  Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.date,
    required this.frequency,
  });
}