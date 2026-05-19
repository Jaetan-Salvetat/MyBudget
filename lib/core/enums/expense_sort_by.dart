import 'package:mybudget/models/expense_model.dart';

enum ExpenseSortBy {
  dateDesc,
  dateAsc,
  amountDesc,
  amountAsc,
  name;

  String get label => switch (this) {
        ExpenseSortBy.dateDesc => 'Plus récent',
        ExpenseSortBy.dateAsc => 'Plus ancien',
        ExpenseSortBy.amountDesc => 'Montant décroissant',
        ExpenseSortBy.amountAsc => 'Montant croissant',
        ExpenseSortBy.name => 'Nom (A-Z)',
      };

  static ExpenseSortBy fromName(String? value) {
    return ExpenseSortBy.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExpenseSortBy.dateDesc,
    );
  }

  List<ExpenseModel> apply(List<ExpenseModel> expenses) {
    final sorted = [...expenses];
    switch (this) {
      case ExpenseSortBy.dateDesc:
        sorted.sort((a, b) => b.startDate.compareTo(a.startDate));
      case ExpenseSortBy.dateAsc:
        sorted.sort((a, b) => a.startDate.compareTo(b.startDate));
      case ExpenseSortBy.amountDesc:
        sorted.sort((a, b) => b.amount.compareTo(a.amount));
      case ExpenseSortBy.amountAsc:
        sorted.sort((a, b) => a.amount.compareTo(b.amount));
      case ExpenseSortBy.name:
        sorted.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    }
    return sorted;
  }
}
