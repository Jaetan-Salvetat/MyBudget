class AccountBalanceData {
  const AccountBalanceData({
    required this.id,
    required this.name,
    required this.bank,
    required this.balance,
  });
  final int id;
  final String name;
  final String bank;
  final double balance;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'bank': bank,
    'balance': balance.toStringAsFixed(2),
  };
}
