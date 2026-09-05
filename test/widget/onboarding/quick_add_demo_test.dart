import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/ui/onboarding/models/onboarding_demo.dart';
import 'package:mybudget/ui/onboarding/widgets/quick_add_demo.dart';

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCategoryOverrideRepository overrideRepository;
  late CategoryTaxonomyService taxonomy;

  setUpAll(() async {
    taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
  });

  setUp(() {
    overrideRepository = MockCategoryOverrideRepository();
    when(() => overrideRepository.getAll()).thenReturn({});
  });

  Future<void> pumpDemo(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryOverrideRepositoryProvider.overrideWithValue(
            overrideRepository,
          ),
          categoryTaxonomyProvider.overrideWith((ref) async => taxonomy),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Center(child: QuickAddDemo(isActive: true)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('montre la catégorie réelle de la phrase, pas son slug', (
    tester,
  ) async {
    await pumpDemo(tester);

    final phrase = OnboardingDemo.phrases.first;
    final expected = taxonomy.resolve(phrase.categorySlug)!;

    expect(find.text(phrase.text), findsOneWidget);
    expect(find.text(expected.label), findsOneWidget);
    expect(find.text(phrase.categorySlug), findsNothing);
  });

  testWidgets('montre le montant et la récurrence lus dans la phrase', (
    tester,
  ) async {
    await pumpDemo(tester);

    final phrase = OnboardingDemo.phrases.first;

    expect(find.textContaining('42'), findsWidgets);
    expect(
      find.text(phrase.frequency.label.toLowerCase()),
      findsOneWidget,
    );
  });
}
