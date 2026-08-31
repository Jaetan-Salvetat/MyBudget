import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/services/quick_add/nano_quick_add_prompt.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CategoryTaxonomyService taxonomy;
  late NanoQuickAddPrompt prompt;

  setUpAll(() async {
    taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
    prompt = NanoQuickAddPrompt(taxonomy.selectableLeaves);
  });

  String build({bool isRetry = false}) =>
      prompt.forInput('sfr', isRetry: isRetry);

  group('NanoQuickAddPrompt', () {
    test('sépare chaque bloc par ## comme le demande Google', () {
      final text = build();

      for (final section in ['## Tâche', '## Règles', '## Catégories',
        '## Exemples', '## Saisie']) {
        expect(text, contains(section));
      }
    });

    test('reste sous le budget de 1024 tokens recommandé', () {
      expect(build().length, lessThan(4 * 1024));
    });

    test('liste chaque feuille sélectionnable', () {
      final text = build();

      for (final node in taxonomy.selectableLeaves) {
        expect(text, contains(node.slug));
      }
    });

    test('autorise le modèle à mobiliser ce qu\'il sait des enseignes', () {
      expect(build(), contains('Marque ou enseigne'));
    });

    test('ne finit pas ses exemples sur un virement', () {
      final examples = build()
          .split('## Exemples')
          .last
          .split('## Saisie')
          .first
          .trim()
          .split('\n');

      expect(examples.last, isNot(contains('transfert.')));
    });

    test('couvre dépense et revenu, ponctuel et fixe', () {
      final examples = build().split('## Exemples').last;

      expect(examples, contains('salaire.salaire_net'));
      expect(examples, contains('restauration.restaurant'));
      expect(examples, contains('· fixe ·'));
      expect(examples, contains('· ponctuel ·'));
    });

    test('termine par la saisie à classer', () {
      expect(build().trimRight(), endsWith('## Saisie\nsfr'));
    });

    test('ajoute un bloc de correction au second essai', () {
      expect(build(isRetry: true), contains('## Correction'));
      expect(build(), isNot(contains('## Correction')));
    });
  });
}
