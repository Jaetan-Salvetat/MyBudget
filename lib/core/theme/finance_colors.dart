import 'package:flutter/material.dart';

@immutable
class FinanceColors extends ThemeExtension<FinanceColors> {
  final Color income;
  final Color incomeSoft;
  final Color incomeOnSoft;
  final Color expense;
  final Color expenseSoft;
  final Color expenseOnSoft;
  final CategoryPalette categories;

  const FinanceColors({
    required this.income,
    required this.incomeSoft,
    required this.incomeOnSoft,
    required this.expense,
    required this.expenseSoft,
    required this.expenseOnSoft,
    required this.categories,
  });

  static const FinanceColors light = FinanceColors(
    income: Color(0xFF1F8A5B),
    incomeSoft: Color(0xFFDFF5E9),
    incomeOnSoft: Color(0xFF0C5232),
    expense: Color(0xFFC73E36),
    expenseSoft: Color(0xFFFBE3E1),
    expenseOnSoft: Color(0xFF6B1814),
    categories: CategoryPalette.light,
  );

  static const FinanceColors dark = FinanceColors(
    income: Color(0xFF6EE7AC),
    incomeSoft: Color(0x296EE7AC),
    incomeOnSoft: Color(0xFFC5FBDC),
    expense: Color(0xFFFF8B82),
    expenseSoft: Color(0x29FF8B82),
    expenseOnSoft: Color(0xFFFFD1CD),
    categories: CategoryPalette.dark,
  );

  @override
  FinanceColors copyWith({
    Color? income,
    Color? incomeSoft,
    Color? incomeOnSoft,
    Color? expense,
    Color? expenseSoft,
    Color? expenseOnSoft,
    CategoryPalette? categories,
  }) {
    return FinanceColors(
      income: income ?? this.income,
      incomeSoft: incomeSoft ?? this.incomeSoft,
      incomeOnSoft: incomeOnSoft ?? this.incomeOnSoft,
      expense: expense ?? this.expense,
      expenseSoft: expenseSoft ?? this.expenseSoft,
      expenseOnSoft: expenseOnSoft ?? this.expenseOnSoft,
      categories: categories ?? this.categories,
    );
  }

  @override
  FinanceColors lerp(ThemeExtension<FinanceColors>? other, double t) {
    if (other is! FinanceColors) return this;
    return FinanceColors(
      income: Color.lerp(income, other.income, t)!,
      incomeSoft: Color.lerp(incomeSoft, other.incomeSoft, t)!,
      incomeOnSoft: Color.lerp(incomeOnSoft, other.incomeOnSoft, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseSoft: Color.lerp(expenseSoft, other.expenseSoft, t)!,
      expenseOnSoft: Color.lerp(expenseOnSoft, other.expenseOnSoft, t)!,
      categories: categories.lerp(other.categories, t),
    );
  }
}

@immutable
class CategoryPalette {
  final Color food;
  final Color housing;
  final Color transport;
  final Color leisure;
  final Color subscription;
  final Color health;
  final Color shopping;
  final Color other;

  const CategoryPalette({
    required this.food,
    required this.housing,
    required this.transport,
    required this.leisure,
    required this.subscription,
    required this.health,
    required this.shopping,
    required this.other,
  });

  static const CategoryPalette light = CategoryPalette(
    food: Color(0xFFF4A261),
    housing: Color(0xFF6F8DD8),
    transport: Color(0xFF8B5CF6),
    leisure: Color(0xFFEC4899),
    subscription: Color(0xFF06B6D4),
    health: Color(0xFF14B8A6),
    shopping: Color(0xFFF59E0B),
    other: Color(0xFF94A3B8),
  );

  static const CategoryPalette dark = CategoryPalette(
    food: Color(0xFFF4A261),
    housing: Color(0xFF8AA4E0),
    transport: Color(0xFFA78BFA),
    leisure: Color(0xFFF472B6),
    subscription: Color(0xFF22D3EE),
    health: Color(0xFF2DD4BF),
    shopping: Color(0xFFFBBF24),
    other: Color(0xFFB8C0CC),
  );

  CategoryPalette lerp(CategoryPalette other, double t) {
    return CategoryPalette(
      food: Color.lerp(food, other.food, t)!,
      housing: Color.lerp(housing, other.housing, t)!,
      transport: Color.lerp(transport, other.transport, t)!,
      leisure: Color.lerp(leisure, other.leisure, t)!,
      subscription: Color.lerp(subscription, other.subscription, t)!,
      health: Color.lerp(health, other.health, t)!,
      shopping: Color.lerp(shopping, other.shopping, t)!,
      other: Color.lerp(this.other, other.other, t)!,
    );
  }
}

extension FinanceColorsX on ThemeData {
  FinanceColors get financeColors =>
      extension<FinanceColors>() ?? FinanceColors.light;
}

extension FinanceColorsContextX on BuildContext {
  FinanceColors get financeColors => Theme.of(this).financeColors;
}
