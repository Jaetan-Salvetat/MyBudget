import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/constants/quick_add_labels.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/ui/capture/widgets/quick_add_hint_typer.dart';
import 'package:mybudget/ui/onboarding/models/onboarding_demo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CategoryTaxonomyService taxonomy;

  setUpAll(() async {
    taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
  });

  test(
    'chaque catégorie de démo est une catégorie vivante de la taxonomie',
    () {
      final selectable = taxonomy.selectableLeaves
          .map((node) => node.slug)
          .toSet();

      for (final slug in OnboardingDemo.slugs) {
        expect(
          selectable,
          contains(slug),
          reason: '$slug est absent de la taxonomie ou déprécié',
        );
      }
    },
  );

  test('les catégories montrées à la saisie sont connues du modèle', () {
    for (final slug in OnboardingDemo.quickAddSlugs) {
      expect(QuickAddLabels.categories, contains(slug));
    }
  });

  test('les phrases de démo sont celles du champ de saisie', () {
    final demoPhrases = [
      ...OnboardingDemo.phrases.map((phrase) => phrase.text),
      OnboardingDemo.recurrence.phrase,
    ];

    for (final phrase in demoPhrases) {
      expect(QuickAddHintTyper.catalog, contains(phrase));
    }
  });

  test('le total du ticket est la somme de ses lignes', () {
    expect(OnboardingDemo.receipt.total, closeTo(12.40, 0.001));
  });
}
