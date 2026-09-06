import 'package:mybudget/core/services/data/legacy_category_mapper.dart';

class LegacyBackupUpgrader {
  const LegacyBackupUpgrader(this._mapper);
  static const String _categoriesKey = 'categories';
  static const String _categoryIdKey = 'categoryId';
  static const String _categorySlugKey = 'categorySlug';
  static const String _expensesKey = 'expenses';

  final LegacyCategoryMapper _mapper;

  Map<String, dynamic> upgrade(Map<String, dynamic> data) {
    final categories = data[_categoriesKey];
    if (categories is! List) return data;

    final names = <int, String>{};
    for (final item in categories) {
      if (item is! Map) continue;
      final id = int.tryParse(item['id'].toString());
      final name = item['name'];
      if (id != null && name is String) names[id] = name;
    }

    final upgraded = Map<String, dynamic>.from(data)..remove(_categoriesKey);
    final expenses = data[_expensesKey];
    if (expenses is! List) return upgraded;

    upgraded[_expensesKey] = [
      for (final item in expenses)
        if (item is Map)
          _upgradeExpense(Map<String, dynamic>.from(item), names)
        else
          item,
    ];

    return upgraded;
  }

  Map<String, dynamic> _upgradeExpense(
    Map<String, dynamic> expense,
    Map<int, String> names,
  ) {
    final legacyId = int.tryParse(expense.remove(_categoryIdKey).toString());
    if (expense[_categorySlugKey] is String) return expense;

    final name = legacyId == null ? null : names[legacyId];
    expense[_categorySlugKey] = name == null
        ? LegacyCategoryMapper.fallback
        : _mapper.expenseSlugFor(name);

    return expense;
  }
}
