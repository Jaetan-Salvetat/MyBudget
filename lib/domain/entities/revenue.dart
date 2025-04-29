abstract class Revenue {
  final String id;
  final String name;
  final double amount;
  final bool isRegular;
  final DateTime date;
  final String accountId;

  Revenue({
    required this.id,
    required this.name,
    required this.amount,
    required this.isRegular,
    required this.date,
    required this.accountId,
  });

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