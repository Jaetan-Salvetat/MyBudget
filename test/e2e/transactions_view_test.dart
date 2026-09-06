import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/data/model/account_model.dart';
import 'package:mybudget/data/model/expense_model.dart';
import 'package:mybudget/data/provider/expenses_provider.dart';
import 'package:mybudget/ui/shared/expense_queries.dart';
import 'package:mybudget/ui/shared/selected_month_provider.dart';

import 'harness/e2e_harness.dart';

void main() {
  late E2EHarness app;
  late int courant;

  final DateTime now = E2EHarness.defaultNow;

  setUp(() async {
    app = await E2EHarness.start(now: now);
    courant = app.accounts.add(
      AccountModel.create(name: 'Courant', bank: 'Boursorama'),
    );
  });

  tearDown(() => app.dispose());

  Future<int> addExpense({
    required String name,
    required double amount,
    String categorySlug = 'alimentation.courses',
    Frequency frequency = Frequency.oneTime,
    DateTime? startDate,
    int? accountId,
    int? beneficiaryId,
  }) {
    return app.container
        .read(expenseProvider.notifier)
        .addExpense(
          ExpenseModel.create(
            name: name,
            amount: amount,
            categorySlug: categorySlug,
            startDate: startDate ?? DateTime(2026, 6, 4),
            frequency: frequency,
            accountId: accountId ?? courant,
            beneficiaryId: beneficiaryId,
          ),
        );
  }

  group('le mois affiché', () {
    test('ne montre que les dépenses qui y tombent', () async {
      await addExpense(
        name: 'Juin',
        amount: 10,
        startDate: DateTime(2026, 6, 4),
      );
      await addExpense(
        name: 'Mai',
        amount: 20,
        startDate: DateTime(2026, 5, 4),
      );

      expect(
        app.container
            .read(monthExpensesProvider)
            .map((ExpenseModel e) => e.name),
        <String>['Juin'],
      );
    });

    test('suit le mois choisi', () async {
      await addExpense(
        name: 'Mai',
        amount: 20,
        startDate: DateTime(2026, 5, 4),
      );

      app.container.read(selectedMonthProvider.notifier).previousMonth();

      expect(
        app.container
            .read(monthExpensesProvider)
            .map((ExpenseModel e) => e.name),
        <String>['Mai'],
      );
    });

    test('projette une mensuelle sur le jour du mois affiché', () async {
      await addExpense(
        name: 'Loyer',
        amount: 900,
        frequency: Frequency.monthly,
        categorySlug: 'logement.loyer',
        startDate: DateTime(2026, 1, 5),
      );

      final ExpenseModel projected = app.container
          .read(monthExpensesProvider)
          .single;

      expect(projected.startDate, DateTime(2026, 6, 5));
    });

    test('revient au mois courant sur demande', () async {
      final SelectedMonth month = app.container.read(
        selectedMonthProvider.notifier,
      );
      month.previousMonth();
      month.previousMonth();

      month.resetToCurrentMonth();

      expect(app.container.read(selectedMonthProvider), DateTime(2026, 6));
    });
  });
}
