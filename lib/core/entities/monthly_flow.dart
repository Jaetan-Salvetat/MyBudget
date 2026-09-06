class MonthlyFlow {
  final DateTime month;
  final double incomes;
  final double expenses;

  const MonthlyFlow({
    required this.month,
    required this.incomes,
    required this.expenses,
  });

  double get net => incomes - expenses;

  bool get isEmpty => incomes == 0 && expenses == 0;
}
