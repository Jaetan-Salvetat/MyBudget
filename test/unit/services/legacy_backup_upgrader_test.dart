import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/data/legacy_backup_upgrader.dart';
import 'package:mybudget/core/services/data/legacy_category_mapper.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LegacyBackupUpgrader upgrader;

  setUpAll(() async {
    final taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
    upgrader = LegacyBackupUpgrader(LegacyCategoryMapper(taxonomy));
  });

  Map<String, dynamic> legacyBackup() => {
    'version': 2,
    'categories': [
      {'id': '1', 'name': 'Alimentation', 'icon': 'restaurant'},
      {'id': '2', 'name': 'Transport', 'icon': 'directions_car'},
    ],
    'expenses': [
      {'id': '10', 'name': 'Courses', 'categoryId': '1', 'date': '2026-01-05'},
      {'id': '11', 'name': 'Péage', 'categoryId': '2', 'date': '2026-01-06'},
      {'id': '12', 'name': 'Inconnu', 'categoryId': '404'},
    ],
  };

  test('maps legacy category ids to taxonomy slugs', () {
    final upgraded = upgrader.upgrade(legacyBackup());
    final expenses = (upgraded['expenses'] as List)
        .cast<Map<String, dynamic>>();

    expect(expenses.map((e) => e['categorySlug']), [
      'alimentation.courses',
      'transport.carburant',
      LegacyCategoryMapper.fallback,
    ]);
  });

  test('drops the legacy category list and ids', () {
    final upgraded = upgrader.upgrade(legacyBackup());
    final expenses = (upgraded['expenses'] as List)
        .cast<Map<String, dynamic>>();

    expect(upgraded.containsKey('categories'), isFalse);
    expect(expenses.every((e) => e.containsKey('categoryId')), isFalse);
  });

  test('leaves the source payload untouched', () {
    final source = legacyBackup();
    upgrader.upgrade(source);

    expect(source['categories'], isA<List<Map<String, dynamic>>>());
    expect(
      (source['expenses'] as List).first as Map<String, dynamic>,
      containsPair('categoryId', '1'),
    );
  });

  test('returns a current payload unchanged', () {
    final current = {
      'version': 3,
      'expenses': [
        {'id': '10', 'name': 'Courses', 'categorySlug': 'divers.animaux'},
      ],
    };

    final upgraded = upgrader.upgrade(current);

    expect(upgraded, current);
  });

  test('keeps a slug already present on a legacy expense', () {
    final data = legacyBackup();
    (data['expenses'] as List)[0] = {
      'id': '10',
      'name': 'Courses',
      'categoryId': '1',
      'categorySlug': 'divers.animaux',
    };

    final upgraded = upgrader.upgrade(data);
    final first = (upgraded['expenses'] as List).first as Map<String, dynamic>;

    expect(first['categorySlug'], 'divers.animaux');
  });
}
