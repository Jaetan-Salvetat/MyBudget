import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String schemaPath =
      'android/app/src/main/kotlin/fr/jaetan/mybudget/nano/QuickAddOutput.kt';

  late String source;
  late List<String> taxonomySlugs;

  setUpAll(() async {
    source = File(schemaPath).readAsStringSync();
    final taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
    taxonomySlugs = taxonomy.leaves
        .where((node) => !node.isDeprecated && node.aliasOf == null)
        .map((node) => node.slug)
        .toList();
  });

  List<String> firstEnumValues() {
    final open = source.indexOf('enumValues = [');
    final close = source.indexOf(']', open);
    return RegExp(r'"([^"]+)"')
        .allMatches(source.substring(open, close))
        .map((match) => match.group(1)!)
        .toList();
  }

  group('QuickAddOutput.kt', () {
    test('est marqué comme généré', () {
      expect(source, contains('tool/generate_nano_schema.dart'));
      expect(source, contains('DO NOT EDIT'));
    });

    test('contraint le décodage aux feuilles sélectionnables', () {
      expect(firstEnumValues(), taxonomySlugs);
    });

    test('contraint la récurrence aux deux libellés du prompt', () {
      expect(source, contains('enumValues = ["ponctuel", "fixe"]'));
    });

    test('déclare les quatre champs attendus par le parseur Dart', () {
      expect(source, contains('val categorySlug: String'));
      expect(source, contains('val alternatives: List<String>'));
      expect(source, contains('val recurrence: String'));
      expect(source, contains('val name: String'));
    });
  });
}
