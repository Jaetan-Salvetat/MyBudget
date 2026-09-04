import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/models/category_override_model.dart';
import 'package:mybudget/ui/settings/screens/categories_screen.dart';

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCategoryOverrideRepository repository;
  late CategoryTaxonomyService taxonomy;

  setUpAll(() async {
    registerFallbackValue(CategoryOverrideModel.create(slug: 'a.b'));
    taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
  });

  setUp(() {
    repository = MockCategoryOverrideRepository();
    when(() => repository.getAll()).thenReturn({});
    when(() => repository.get(any())).thenReturn(null);
    when(() => repository.save(any())).thenReturn(null);
    when(() => repository.delete(any())).thenReturn(null);
  });

  Future<void> openForm(WidgetTester tester) async {
    await tester.tap(find.byIcon(Symbols.tune_rounded).first);
    await tester.pumpAndSettle();
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryOverrideRepositoryProvider.overrideWithValue(repository),
          categoryTaxonomyProvider.overrideWith((ref) async => taxonomy),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const CategoriesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapSection(WidgetTester tester, String label) async {
    await tester.scrollUntilVisible(
      find.text(label),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('both type sections start expanded', (tester) async {
    await pumpScreen(tester);

    expect(find.text('D\u00e9penses'), findsOneWidget);
    expect(find.text('Alimentation'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Salaire'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Revenus'), findsOneWidget);
    expect(find.text('Salaire'), findsOneWidget);
  });

  testWidgets('a collapsed section reopens on tap', (tester) async {
    await pumpScreen(tester);

    await tapSection(tester, 'D\u00e9penses');
    expect(find.text('Alimentation'), findsNothing);

    await tapSection(tester, 'D\u00e9penses');

    expect(find.text('Alimentation'), findsOneWidget);
  });

  testWidgets('collapsing a section hides its groups', (tester) async {
    await pumpScreen(tester);

    await tapSection(tester, 'D\u00e9penses');

    expect(find.text('Alimentation'), findsNothing);
  });

  testWidgets('a search drops the section with no match', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'salaire');
    await tester.pumpAndSettle();

    expect(find.text('Salaire'), findsWidgets);
    expect(find.text('D\u00e9penses'), findsNothing);
  });

  testWidgets('a group reveals its leaves once tapped', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Courses'), findsNothing);

    await tester.tap(find.text('Alimentation'));
    await tester.pumpAndSettle();

    expect(find.text('Courses'), findsOneWidget);
  });

  testWidgets('search keeps only the matching leaves, group included', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'cafe');
    await tester.pumpAndSettle();

    expect(find.text('Café'), findsOneWidget);
    expect(find.text('Restauration'), findsOneWidget);
    expect(find.text('Alimentation'), findsNothing);
  });

  testWidgets('search matches a group label and shows all its leaves', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'alimentation');
    await tester.pumpAndSettle();

    expect(find.text('Courses'), findsOneWidget);
    expect(find.text('Pain & pâtisserie'), findsOneWidget);
  });

  testWidgets('marks a customised category', (tester) async {
    when(() => repository.getAll()).thenReturn({
      'alimentation': CategoryOverrideModel.create(
        slug: 'alimentation',
        name: 'Courses',
      ),
    });

    await pumpScreen(tester);

    expect(find.text('Courses'), findsOneWidget);
    expect(find.byIcon(Symbols.edit_rounded), findsOneWidget);
  });

  testWidgets('saving the form closes it without closing the list', (
    tester,
  ) async {
    await pumpScreen(tester);

    await openForm(tester);
    expect(find.text('Enregistrer'), findsOneWidget);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Enregistrer'), findsNothing);
    expect(find.text('Alimentation'), findsOneWidget);
  });

  testWidgets('an untouched form stores nothing', (tester) async {
    await pumpScreen(tester);

    await openForm(tester);
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final saved = verify(
      () => repository.save(captureAny()),
    ).captured.cast<CategoryOverrideModel>();

    expect(saved.single.isEmpty, isTrue);
  });

  testWidgets('resetting deletes the override', (tester) async {
    when(() => repository.getAll()).thenReturn({
      'alimentation': CategoryOverrideModel.create(
        slug: 'alimentation',
        name: 'Courses',
      ),
    });

    await pumpScreen(tester);

    await openForm(tester);

    await tester.tap(find.text('Réinitialiser'));
    await tester.pumpAndSettle();

    verify(() => repository.delete('alimentation')).called(1);
  });
}
