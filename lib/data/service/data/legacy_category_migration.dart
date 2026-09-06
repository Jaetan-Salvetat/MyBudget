import 'package:mybudget/data/repository/expense_repository.dart';
import 'package:mybudget/data/repository/legacy_category_repository.dart';
import 'package:mybudget/data/service/data/legacy_category_mapper.dart';
import 'package:mybudget/data/service/preferences_service.dart';

class LegacyCategoryMigration {
  const LegacyCategoryMigration({
    required this.expenses,
    required this.legacyCategories,
    required this.mapper,
  });
  final ExpenseRepository expenses;
  final LegacyCategoryRepository legacyCategories;
  final LegacyCategoryMapper mapper;

  Future<void> run() async {
    if (PreferencesService.isLegacyCategoryMigrationDone()) return;

    final names = legacyCategories.namesById();

    for (final expense in expenses.getAll()) {
      final legacyId = expense.legacyCategoryId;
      if (legacyId == null || expense.categorySlug != null) continue;

      final legacyName = names[legacyId];
      expense.categorySlug = legacyName == null
          ? LegacyCategoryMapper.fallback
          : mapper.expenseSlugFor(legacyName);
      expenses.update(expense);
    }

    await PreferencesService.setLegacyCategoryMigrationDone();
  }
}
