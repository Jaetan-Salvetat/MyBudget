class UpcomingItemData {
  final String name;
  final double amount;
  final int day;
  final String type;
  final String? categoryIcon;

  const UpcomingItemData({
    required this.name,
    required this.amount,
    required this.day,
    required this.type,
    this.categoryIcon,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'amount': amount.toStringAsFixed(2),
    'day': day,
    'type': type,
    if (categoryIcon != null) 'icon': categoryIcon,
  };
}
