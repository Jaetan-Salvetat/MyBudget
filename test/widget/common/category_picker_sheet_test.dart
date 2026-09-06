import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/ui/common/widgets/category_picker_sheet.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockExpenseRepository expenseRepository;
  late MockRevenueRepository revenueRepository;
  late MockCategoryOverrideRepository overrideRepository;
  late CategoryTaxonomyService taxonomy;

  setUpAll(() async {
    taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
  });

  setUp(() {
    expenseRepository = MockExpenseRepository();
    revenueRepository = MockRevenueRepository();
    overrideRepository = MockCategoryOverrideRepository();

    when(() => expenseRepository.getActive()).thenReturn([]);

    when(() => expenseRepository.getClosed()).thenReturn([]);
    when(() => revenueRepository.getActive()).thenReturn([]);
    when(() => revenueRepository.getClosed()).thenReturn([]);
    when(() => overrideRepository.getAll()).thenReturn({});
  });

  ExpenseModel expense(String slug) => ExpenseModel.create(
    name: 'x',
    amount: 10,
    categorySlug: slug,
    accountId: 1,
    startDate: DateTime(2026, 1, 1),
    frequency: 'Mensuel',
  );

  Future<String? Function()> openPicker(
    WidgetTester tester, {
    TransactionType? type = TransactionType.expense,
    String? selectedSlug,
    List<String> suggestions = const [],
  }) async {
    String? picked;
    var closed = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(expenseRepository),
          revenueRepositoryProvider.overrideWithValue(revenueRepository),
          categoryOverrideRepositoryProvider.overrideWithValue(
            overrideRepository,
          ),
          categoryTaxonomyProvider.overrideWith((ref) async => taxonomy),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  picked = await CategoryPickerSheet.show(
                    context,
                    type: type,
                    selectedSlug: selectedSlug,
                    suggestions: suggestions,
                  );
                  closed = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    return () {
      expect(closed, isTrue);
      return picked;
    };
  }

  testWidgets('returns the leaf slug picked under a group', (tester) async {
    final result = await openPicker(tester);

    expect(find.text('Courses'), findsNothing);

    await tester.tap(find.text('Alimentation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Courses'));
    await tester.pumpAndSettle();

    expect(result(), 'alimentation.courses');
  });

  testWidgets('search flattens the tree to matching leaves', (tester) async {
    final result = await openPicker(tester);

    await tester.enterText(find.byType(TextField), 'patiss');
    await tester.pumpAndSettle();

    expect(find.text('Alimentation'), findsOneWidget);
    expect(find.text('Pain & pâtisserie'), findsOneWidget);

    await tester.tap(find.text('Pain & pâtisserie'));
    await tester.pumpAndSettle();

    expect(result(), 'alimentation.pain_patisserie');
  });

  testWidgets('opens the group of the current selection', (tester) async {
    await openPicker(tester, selectedSlug: 'transport.peage');

    expect(find.text('Péage'), findsOneWidget);
  });

  testWidgets('lists the most used categories first', (tester) async {
    when(
      () => expenseRepository.getActive(),
    ).thenReturn([expense('logement.loyer')]);

    await openPicker(tester);

    expect(find.text('FRÉQUENTES'), findsOneWidget);
    expect(find.text('Loyer'), findsOneWidget);
  });

  testWidgets('without a type, both sections are browsable', (tester) async {
    final result = await openPicker(tester, type: null);

    expect(find.text('DÉPENSES'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('REVENUS'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salaire'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salaire net'));
    await tester.pumpAndSettle();

    expect(result(), 'salaire.salaire_net');
  });

  testWidgets('without a type, search spans both sections', (tester) async {
    final result = await openPicker(tester, type: null);

    await tester.enterText(find.byType(TextField), 'prime');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Prime'));
    await tester.pumpAndSettle();

    expect(result(), 'salaire.prime');
  });

  testWidgets('a suggested category is not repeated in the frequent list', (
    tester,
  ) async {
    when(
      () => expenseRepository.getActive(),
    ).thenReturn([expense('logement.loyer')]);

    await openPicker(tester, suggestions: const ['logement.loyer']);

    expect(find.text('SUGGESTIONS'), findsOneWidget);
    expect(find.text('FRÉQUENTES'), findsNothing);
    expect(find.text('Loyer'), findsOneWidget);
  });
}
