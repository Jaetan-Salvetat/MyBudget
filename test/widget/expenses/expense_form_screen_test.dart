import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/beneficiary_repository.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/ui/common/widgets/effective_month_field.dart';
import 'package:mybudget/ui/expenses/screens/expense_form_screen.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

class MockBeneficiaryRepository extends Mock implements BeneficiaryRepository {}

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
    await initializeDateFormatting('fr_FR', null);
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

  Future<ExpenseModel? Function()> pushForm(
    WidgetTester tester, {
    ExpenseModel? expense,
    List<ExpenseModel> closedExpenses = const [],
  }) async {
    ExpenseModel? submitted;
    late BuildContext pageContext;

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
          home: Builder(
            builder: (context) {
              pageContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    unawaited(
      ExpenseFormScreen.push(
        context: pageContext,
        accounts: [account],
        expense: expense,
        closedExpenses: closedExpenses,
      ).then((value) => submitted = value),
    );
    await tester.pumpAndSettle();

    return () => submitted;
  }

  Future<void> submit(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('refuses an empty name', (WidgetTester tester) async {
    final submitted = await pushForm(tester);

    await tester.enterText(find.byType(TextField).at(1), '12,50');
    await submit(tester, 'Ajouter');

    expect(find.text('Veuillez saisir un nom'), findsOneWidget);
    expect(submitted(), isNull);
  });

  testWidgets('refuses a blank name', (WidgetTester tester) async {
    final submitted = await pushForm(tester);

    await tester.enterText(find.byType(TextField).first, '   ');
    await tester.enterText(find.byType(TextField).at(1), '12,50');
    await submit(tester, 'Ajouter');

    expect(find.text('Veuillez saisir un nom'), findsOneWidget);
    expect(submitted(), isNull);
  });

  testWidgets('clears the name error once a name is entered', (
    WidgetTester tester,
  ) async {
    await pushForm(tester);

    await tester.enterText(find.byType(TextField).at(1), '12,50');
    await submit(tester, 'Ajouter');
    expect(find.text('Veuillez saisir un nom'), findsOneWidget);

    await tester.ensureVisible(find.byType(TextField).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Loyer');
    await submit(tester, 'Ajouter');

    expect(find.text('Veuillez saisir un nom'), findsNothing);
  });

  testWidgets('pops the edited expense back to the caller', (
    WidgetTester tester,
  ) async {
    final expense = ExpenseModel.create(
      name: 'Loyer',
      amount: 800,
      startDate: DateTime(2026, 1, 1),
      accountId: account.id,
      frequency: Frequency.monthly,
      categorySlug: 'logement_loyer',
    )..id = 7;

    final submitted = await pushForm(tester, expense: expense);

    await tester.enterText(find.byType(TextField).first, 'Charges');
    await submit(tester, 'Enregistrer');

    expect(submitted()?.name, 'Charges');
    expect(find.byType(ExpenseFormScreen), findsNothing);
  });

  testWidgets('pops nothing when the user backs out', (
    WidgetTester tester,
  ) async {
    final submitted = await pushForm(tester);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(submitted(), isNull);
    expect(find.byType(ExpenseFormScreen), findsNothing);
  });

  group('the month a new expense starts on', () {
    final closed = ExpenseModel.create(
      name: 'Netflix',
      amount: 15.99,
      startDate: DateTime(2026, 1, 12),
      accountId: 1,
      frequency: Frequency.monthly,
      categorySlug: 'loisirs.abonnements',
    )..id = 3;

    Future<ExpenseModel? Function()> formFilledFromClosed(
      WidgetTester tester,
    ) async {
      final submitted = await pushForm(tester, closedExpenses: [closed]);

      await tester.tap(find.text('Reprendre une ancienne dépense'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Netflix'));
      await tester.pumpAndSettle();

      return submitted;
    }

    Finder theSwitch() => find.descendant(
      of: find.byType(EffectiveMonthField),
      matching: find.byType(FrostedSwitch),
    );

    testWidgets('is offered on a monthly expense', (tester) async {
      await pushForm(tester);

      expect(find.byType(EffectiveMonthField), findsOneWidget);
    });

    testWidgets('is not offered on a one-off', (tester) async {
      await pushForm(tester);

      await tester.tap(find.text('Ponctuel'));
      await tester.pumpAndSettle();

      expect(find.byType(EffectiveMonthField), findsNothing);
    });

    testWidgets('is not offered when editing an expense', (tester) async {
      final expense = ExpenseModel.create(
        name: 'Loyer',
        amount: 800,
        startDate: DateTime(2026, 1, 1),
        accountId: account.id,
        frequency: Frequency.monthly,
        categorySlug: 'logement.loyer',
      )..id = 7;

      await pushForm(tester, expense: expense);

      expect(find.byType(EffectiveMonthField), findsNothing);
    });

    testWidgets('is the month in progress by default', (tester) async {
      final submitted = await formFilledFromClosed(tester);

      await submit(tester, 'Ajouter');

      final now = DateTime.now();
      expect(submitted()?.startDate, DateTime(now.year, now.month, now.day));
    });

    testWidgets('moves to the month after once the switch is off', (
      tester,
    ) async {
      final submitted = await formFilledFromClosed(tester);

      await tester.ensureVisible(theSwitch());
      await tester.pumpAndSettle();
      await tester.tap(theSwitch());
      await tester.pumpAndSettle();
      await submit(tester, 'Ajouter');

      final now = DateTime.now();
      final nextMonth = DateTime(now.year, now.month + 1);
      final daysInNextMonth = DateTime(now.year, now.month + 2, 0).day;
      expect(
        submitted()?.startDate,
        DateTime(
          nextMonth.year,
          nextMonth.month,
          now.day > daysInNextMonth ? daysInNextMonth : now.day,
        ),
      );
    });
  });
}
