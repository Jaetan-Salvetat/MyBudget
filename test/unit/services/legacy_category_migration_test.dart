import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/legacy_category_repository.dart';
import 'package:mybudget/core/services/data/legacy_category_mapper.dart';
import 'package:mybudget/core/services/data/legacy_category_migration.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockLegacyCategoryRepository extends Mock
    implements LegacyCategoryRepository {}

class FakeExpenseModel extends Fake implements ExpenseModel {}

ExpenseModel _expense({
  required int id,
  int? legacyCategoryId,
  String? categorySlug,
}) =>
    ExpenseModel.create(
        name: 'Courses',
        amount: 12,
        startDate: DateTime(2026, 1, 1),
        frequency: Frequency.monthly,
        accountId: 1,
        categorySlug: categorySlug,
      )
      ..id = id
      ..legacyCategoryId = legacyCategoryId;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockExpenseRepository expenses;
  late MockLegacyCategoryRepository legacyCategories;
  late LegacyCategoryMigration migration;

  setUpAll(() async {
    registerFallbackValue(FakeExpenseModel());
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.init();

    final taxonomy = CategoryTaxonomyService();
    await taxonomy.load();

    expenses = MockExpenseRepository();
    legacyCategories = MockLegacyCategoryRepository();
    when(() => expenses.update(any())).thenReturn(1);

    migration = LegacyCategoryMigration(
      expenses: expenses,
      legacyCategories: legacyCategories,
      mapper: LegacyCategoryMapper(taxonomy),
    );
  });

  test('maps every legacy id to its taxonomy slug', () async {
    when(
      () => legacyCategories.namesById(),
    ).thenReturn({1: 'Alimentation', 2: 'Transport'});
    when(() => expenses.getAll()).thenReturn([
      _expense(id: 10, legacyCategoryId: 1),
      _expense(id: 11, legacyCategoryId: 2),
    ]);

    await migration.run();

    final saved = verify(
      () => expenses.update(captureAny()),
    ).captured.cast<ExpenseModel>();
    expect(saved.map((e) => e.categorySlug), [
      'alimentation.courses',
      'transport.carburant',
    ]);
  });

  test('maps a deleted legacy category to the fallback', () async {
    when(() => legacyCategories.namesById()).thenReturn({1: 'Alimentation'});
    when(
      () => expenses.getAll(),
    ).thenReturn([_expense(id: 10, legacyCategoryId: 99)]);

    await migration.run();

    final saved =
        verify(() => expenses.update(captureAny())).captured.single
            as ExpenseModel;
    expect(saved.categorySlug, LegacyCategoryMapper.fallback);
  });

  test('leaves an expense that already carries a slug untouched', () async {
    when(() => legacyCategories.namesById()).thenReturn({1: 'Alimentation'});
    when(() => expenses.getAll()).thenReturn([
      _expense(id: 10, legacyCategoryId: 1, categorySlug: 'divers.animaux'),
    ]);

    await migration.run();

    verifyNever(() => expenses.update(any()));
  });

  test('leaves an expense with no legacy id untouched', () async {
    when(() => legacyCategories.namesById()).thenReturn({});
    when(() => expenses.getAll()).thenReturn([_expense(id: 10)]);

    await migration.run();

    verifyNever(() => expenses.update(any()));
  });

  test('marks the migration done so it never runs twice', () async {
    when(() => legacyCategories.namesById()).thenReturn({1: 'Alimentation'});
    when(
      () => expenses.getAll(),
    ).thenReturn([_expense(id: 10, legacyCategoryId: 1)]);

    await migration.run();
    expect(PreferencesService.isLegacyCategoryMigrationDone(), isTrue);

    await migration.run();
    verify(() => expenses.getAll()).called(1);
  });

  test('does nothing on an install that never held legacy data', () async {
    when(() => legacyCategories.namesById()).thenReturn({});
    when(() => expenses.getAll()).thenReturn([]);

    await migration.run();

    verifyNever(() => expenses.update(any()));
    expect(PreferencesService.isLegacyCategoryMigrationDone(), isTrue);
  });
}
