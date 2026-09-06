import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/beneficiary_repository.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/transfer_model.dart';
import 'package:mybudget/ui/transfers/widgets/transfer_bottom_sheet.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

class MockBeneficiaryRepository extends Mock implements BeneficiaryRepository {}

final DateTime _fixedNow = DateTime(2026, 6, 15, 9, 30);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockExpenseRepository expenseRepository;
  late MockRevenueRepository revenueRepository;
  late MockCategoryOverrideRepository overrideRepository;
  late MockBeneficiaryRepository beneficiaryRepository;
  late CategoryTaxonomyService taxonomy;

  setUpAll(() async {
    taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
  });

  setUp(() {
    expenseRepository = MockExpenseRepository();
    revenueRepository = MockRevenueRepository();
    overrideRepository = MockCategoryOverrideRepository();
    beneficiaryRepository = MockBeneficiaryRepository();

    when(() => expenseRepository.getActive()).thenReturn([]);

    when(() => expenseRepository.getClosed()).thenReturn([]);
    when(() => revenueRepository.getActive()).thenReturn([]);
    when(() => revenueRepository.getClosed()).thenReturn([]);
    when(() => overrideRepository.getAll()).thenReturn({});
    when(() => beneficiaryRepository.getAll()).thenReturn([]);
  });

  final account = AccountModel.create(name: 'Courant', bank: 'Banque')..id = 1;

  Future<List<TransferModel>> pumpSheet(
    WidgetTester tester, {
    TransferModel? transfer,
  }) async {
    final submitted = <TransferModel>[];

    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(expenseRepository),
          revenueRepositoryProvider.overrideWithValue(revenueRepository),
          categoryOverrideRepositoryProvider.overrideWithValue(
            overrideRepository,
          ),
          beneficiaryRepositoryProvider.overrideWithValue(
            beneficiaryRepository,
          ),
          categoryTaxonomyProvider.overrideWith((ref) async => taxonomy),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: TransferBottomSheet(
              accounts: [account],
              now: _fixedNow,
              transfer: transfer,
              onSubmit: submitted.add,
              onCancel: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return submitted;
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Ajouter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();
  }

  testWidgets('refuses an empty name', (WidgetTester tester) async {
    final submitted = await pumpSheet(tester);

    await tester.enterText(find.byType(TextField).at(1), '12,50');
    await submit(tester);

    expect(find.text('Veuillez saisir un nom'), findsOneWidget);
    expect(submitted, isEmpty);
  });

  testWidgets('refuses a blank name', (WidgetTester tester) async {
    final submitted = await pumpSheet(tester);

    await tester.enterText(find.byType(TextField).first, '   ');
    await tester.enterText(find.byType(TextField).at(1), '12,50');
    await submit(tester);

    expect(find.text('Veuillez saisir un nom'), findsOneWidget);
    expect(submitted, isEmpty);
  });

  testWidgets('clears the name error once a name is entered', (
    WidgetTester tester,
  ) async {
    await pumpSheet(tester);

    await tester.enterText(find.byType(TextField).at(1), '12,50');
    await submit(tester);
    expect(find.text('Veuillez saisir un nom'), findsOneWidget);

    await tester.ensureVisible(find.byType(TextField).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Épargne');
    await submit(tester);

    expect(find.text('Veuillez saisir un nom'), findsNothing);
  });
}
