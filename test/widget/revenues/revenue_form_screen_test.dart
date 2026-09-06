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
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/common/widgets/effective_month_field.dart';
import 'package:mybudget/ui/revenues/screens/revenue_form_screen.dart';

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

  Future<RevenueModel? Function()> pushForm(
    WidgetTester tester, {
    RevenueModel? revenue,
    List<RevenueModel> closedRevenues = const [],
  }) async {
    RevenueModel? submitted;
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
      RevenueFormScreen.push(
        context: pageContext,
        accounts: [account],
        revenue: revenue,
        closedRevenues: closedRevenues,
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
    await tester.enterText(find.byType(TextField).first, 'Salaire');
    await submit(tester, 'Ajouter');

    expect(find.text('Veuillez saisir un nom'), findsNothing);
  });

  testWidgets('pops the edited revenue back to the caller', (
    WidgetTester tester,
  ) async {
    final revenue = RevenueModel.create(
      name: 'Salaire',
      amount: 2000,
      startDate: DateTime(2026, 1, 1),
      accountId: account.id,
      frequency: Frequency.monthly,
      categorySlug: 'salaire',
    )..id = 7;

    final submitted = await pushForm(tester, revenue: revenue);

    await tester.enterText(find.byType(TextField).first, 'Prime');
    await submit(tester, 'Enregistrer');

    expect(submitted()?.name, 'Prime');
    expect(find.byType(RevenueFormScreen), findsNothing);
  });

  testWidgets('pops nothing when the user backs out', (
    WidgetTester tester,
  ) async {
    final submitted = await pushForm(tester);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(submitted(), isNull);
    expect(find.byType(RevenueFormScreen), findsNothing);
  });

  group('the month a new revenue starts on', () {
    final closed = RevenueModel.create(
      name: 'Prime',
      amount: 250,
      startDate: DateTime(2026, 1, 12),
      accountId: 1,
      frequency: Frequency.monthly,
      categorySlug: 'salaire.prime',
    )..id = 3;

    testWidgets('is offered on a monthly revenue', (tester) async {
      await pushForm(tester);

      expect(find.byType(EffectiveMonthField), findsOneWidget);
    });

    testWidgets('moves to the month after once the switch is off', (
      tester,
    ) async {
      final submitted = await pushForm(tester, closedRevenues: [closed]);

      await tester.tap(find.text('Reprendre un ancien revenu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prime'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byType(EffectiveMonthField),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(EffectiveMonthField),
          matching: find.byType(FrostedSwitch),
        ),
      );
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
