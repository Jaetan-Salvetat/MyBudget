import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/data/model/beneficiary_model.dart';
import 'package:mybudget/data/model/expense_model.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/data/repository/beneficiary_repository.dart';
import 'package:mybudget/data/repository/expense_repository.dart';
import 'package:mybudget/data/repository/revenue_repository.dart';
import 'package:mybudget/ui/settings/screens/beneficiaries_screen.dart';

class MockBeneficiaryRepository extends Mock implements BeneficiaryRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class FakeBeneficiaryModel extends Fake implements BeneficiaryModel {}

const int _anyColor = 0xFF42A5F5;

BeneficiaryModel _beneficiary({required int id, required String name}) {
  final model = BeneficiaryModel.create(name: name, color: _anyColor);
  model.id = id;
  return model;
}

ExpenseModel _expenseOf(int beneficiaryId) {
  final expense = ExpenseModel.create(
    name: 'Netflix',
    amount: 15,
    accountId: 1,
    categorySlug: 'restauration.cafe',
    startDate: DateTime(2026, 1, 1),
    frequency: Frequency.monthly,
  );
  expense.beneficiaryId = beneficiaryId;
  return expense;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockBeneficiaryRepository beneficiaries;
  late MockExpenseRepository expenses;
  late MockRevenueRepository revenues;

  setUpAll(() => registerFallbackValue(FakeBeneficiaryModel()));

  setUp(() {
    beneficiaries = MockBeneficiaryRepository();
    expenses = MockExpenseRepository();
    revenues = MockRevenueRepository();

    when(() => beneficiaries.getAll()).thenReturn([]);
    when(() => beneficiaries.add(any())).thenReturn(1);
    when(() => beneficiaries.update(any())).thenReturn(1);
    when(() => beneficiaries.delete(any())).thenReturn(true);
    when(() => expenses.getAll()).thenReturn([]);
    when(() => revenues.getAll()).thenReturn([]);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          beneficiaryRepositoryProvider.overrideWithValue(beneficiaries),
          expenseRepositoryProvider.overrideWithValue(expenses),
          revenueRepositoryProvider.overrideWithValue(revenues),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const BeneficiariesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists every beneficiary without a divider', (tester) async {
    when(() => beneficiaries.getAll()).thenReturn([
      _beneficiary(id: 1, name: 'Alice'),
      _beneficiary(id: 2, name: 'Paul'),
    ]);

    await pumpScreen(tester);

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Paul'), findsOneWidget);
    expect(find.byType(FrostedDivider), findsNothing);
  });

  testWidgets('tells how many transactions use a beneficiary', (tester) async {
    when(
      () => beneficiaries.getAll(),
    ).thenReturn([_beneficiary(id: 1, name: 'Alice')]);
    when(() => expenses.getAll()).thenReturn([_expenseOf(1), _expenseOf(1)]);

    await pumpScreen(tester);

    expect(find.text('2 transactions'), findsOneWidget);
  });

  testWidgets('shows an empty state when there is no beneficiary', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Aucun bénéficiaire'), findsOneWidget);
  });

  testWidgets('filters the list from the search field', (tester) async {
    when(() => beneficiaries.getAll()).thenReturn([
      for (int index = 0; index < 8; index++)
        _beneficiary(id: index + 1, name: 'Personne $index'),
    ]);

    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'Personne 3');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FrostedListTile, 'Personne 3'), findsOneWidget);
    expect(find.widgetWithText(FrostedListTile, 'Personne 4'), findsNothing);
  });

  testWidgets('hides the search field on a short list', (tester) async {
    when(
      () => beneficiaries.getAll(),
    ).thenReturn([_beneficiary(id: 1, name: 'Alice')]);

    await pumpScreen(tester);

    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('refuses to delete a beneficiary linked to transactions', (
    tester,
  ) async {
    when(
      () => beneficiaries.getAll(),
    ).thenReturn([_beneficiary(id: 1, name: 'Alice')]);
    when(() => expenses.getAll()).thenReturn([_expenseOf(1)]);

    await pumpScreen(tester);

    await tester.tap(find.byIcon(Symbols.delete_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Suppression impossible'), findsOneWidget);
    verifyNever(() => beneficiaries.delete(any()));
  });

  testWidgets('deletes an unused beneficiary after confirmation', (
    tester,
  ) async {
    when(
      () => beneficiaries.getAll(),
    ).thenReturn([_beneficiary(id: 1, name: 'Alice')]);

    await pumpScreen(tester);

    await tester.tap(find.byIcon(Symbols.delete_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer').last);
    await tester.pumpAndSettle();

    verify(() => beneficiaries.delete(1)).called(1);
  });

  testWidgets('adds a beneficiary from the top bar action', (tester) async {
    await pumpScreen(tester);

    expect(find.byType(FrostedFab), findsNothing);

    await tester.tap(find.byIcon(Symbols.add_rounded));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Marie');
    await tester.tap(find.text('Ajouter').last);
    await tester.pumpAndSettle();

    final added =
        verify(() => beneficiaries.add(captureAny())).captured.single
            as BeneficiaryModel;
    expect(added.name, 'Marie');
  });

  testWidgets('renames a beneficiary from its row', (tester) async {
    final model = _beneficiary(id: 1, name: 'Alice');
    when(() => beneficiaries.getAll()).thenReturn([model]);
    when(() => beneficiaries.get(1)).thenReturn(model);

    await pumpScreen(tester);

    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Alicia');
    await tester.tap(find.text('Renommer').last);
    await tester.pumpAndSettle();

    final updated =
        verify(() => beneficiaries.update(captureAny())).captured.last
            as BeneficiaryModel;
    expect(updated.id, 1);
    expect(updated.name, 'Alicia');
  });

  testWidgets('prefills the edit dialog with the current name', (tester) async {
    when(
      () => beneficiaries.getAll(),
    ).thenReturn([_beneficiary(id: 1, name: 'Alice')]);

    await pumpScreen(tester);

    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();

    expect(find.text('Modifier le bénéficiaire'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Alice'), findsOneWidget);
  });
}
