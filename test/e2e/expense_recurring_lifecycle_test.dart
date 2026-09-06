import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/effective_month.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/recurring_deletion.dart';
import 'package:mybudget/core/enums/transaction_change.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/transaction_event_model.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';

import 'harness/e2e_harness.dart';

void main() {
  late E2EHarness app;

  setUp(() async {
    app = await E2EHarness.start();
  });

  tearDown(() => app.dispose());

  Future<int> seedRent({
    double amount = 900,
    int startDay = 5,
    Frequency frequency = Frequency.monthly,
  }) async {
    return app.container
        .read(expenseProvider.notifier)
        .addExpense(
          ExpenseModel.create(
            name: 'Loyer',
            amount: amount,
            categorySlug: 'logement.loyer',
            startDate: DateTime(2026, 1, startDay),
            frequency: frequency,
            accountId: 1,
          ),
        );
  }

  ExpenseModel expenseOf(int id) => app.expenses.table.get(id)!;

  List<TransactionEventModel> eventsOf(int rootId) =>
      app.transactionEvents.getForRoot(rootId, TransactionType.expense);

  group('une dépense mensuelle dont les termes changent', () {
    test('se scinde : l\'ancienne se clôt la veille de la nouvelle', () async {
      final int id = await seedRent();

      await app.container
          .read(expenseProvider.notifier)
          .updateExpense(
            expenseOf(id).copyWith(amount: 950),
            effectiveMonth: EffectiveMonth.thisMonth,
          );

      final ExpenseModel closed = expenseOf(id);
      final ExpenseModel fork = app.expenses.table.all.firstWhere(
        (ExpenseModel row) => row.id != id,
      );

      expect(closed.amount, 900);
      expect(closed.endDate, DateTime(2026, 6, 4));
      expect(fork.amount, 950);
      expect(fork.startDate, DateTime(2026, 6, 5));
      expect(fork.parentId, id);
      expect(fork.endDate, isNull);
    });

    test('reporte la scission au mois suivant quand on le demande', () async {
      final int id = await seedRent();

      await app.container
          .read(expenseProvider.notifier)
          .updateExpense(
            expenseOf(id).copyWith(amount: 950),
            effectiveMonth: EffectiveMonth.nextMonth,
          );

      final ExpenseModel fork = app.expenses.table.all.firstWhere(
        (ExpenseModel row) => row.id != id,
      );

      expect(expenseOf(id).endDate, DateTime(2026, 7, 4));
      expect(fork.startDate, DateTime(2026, 7, 5));
    });

    test('n\'expose que la version en vigueur', () async {
      final int id = await seedRent();

      await app.container
          .read(expenseProvider.notifier)
          .updateExpense(expenseOf(id).copyWith(amount: 950));

      final List<ExpenseModel> active = await app.container.read(
        expenseProvider.future,
      );

      expect(active.map((ExpenseModel e) => e.amount), <double>[950]);
    });

    test(
      'ne consigne rien : la chaîne porte déjà le nouveau montant',
      () async {
        final int id = await seedRent();

        await app.container
            .read(expenseProvider.notifier)
            .updateExpense(expenseOf(id).copyWith(amount: 950));

        expect(eventsOf(id), isEmpty);
      },
    );

    test('scinde aussi sur un simple renommage', () async {
      final int id = await seedRent();

      await app.container
          .read(expenseProvider.notifier)
          .updateExpense(expenseOf(id).copyWith(name: 'Loyer Paris'));

      expect(app.expenses.table.all, hasLength(2));
      expect(expenseOf(id).endDate, isNotNull);
      expect(
        app.expenses.table.all
            .firstWhere((ExpenseModel row) => row.id != id)
            .name,
        'Loyer Paris',
      );
    });
  });

  group('une dépense dont seule la catégorie change', () {
    test('reste en place et consigne le changement', () async {
      final int id = await seedRent();

      await app.container
          .read(expenseProvider.notifier)
          .updateExpense(
            expenseOf(id).copyWith(categorySlug: 'logement.charges'),
          );

      final List<TransactionEventModel> events = eventsOf(id);

      expect(app.expenses.table.all, hasLength(1));
      expect(events, hasLength(1));
      expect(events.single.changeEnum, TransactionChange.category);
      expect(events.single.previousValue, 'logement.loyer');
      expect(events.single.nextValue, 'logement.charges');
    });
  });

  group('une dépense ponctuelle modifiée', () {
    test('est corrigée sur place, sans scission', () async {
      final int id = await seedRent(frequency: Frequency.oneTime, startDay: 5);

      await app.container
          .read(expenseProvider.notifier)
          .updateExpense(expenseOf(id).copyWith(amount: 42));

      expect(app.expenses.table.all, hasLength(1));
      expect(expenseOf(id).amount, 42);
      expect(expenseOf(id).endDate, isNull);
    });
  });

  group('la suppression d\'une dépense mensuelle', () {
    test('« à partir du mois prochain » la clôt aujourd\'hui', () async {
      final int id = await seedRent();

      await app.container.read(expenseProvider.notifier).deleteExpense(id);

      expect(expenseOf(id).endDate, DateTime(2026, 6, 15));
      expect(await app.container.read(expenseProvider.future), isEmpty);
    });

    test('« dès ce mois-ci » la clôt la veille de l\'échéance', () async {
      final int id = await seedRent();

      await app.container
          .read(expenseProvider.notifier)
          .deleteExpense(id, scope: RecurringDeletion.includingThisMonth);

      expect(expenseOf(id).endDate, DateTime(2026, 6, 4));
    });

    test('efface la ligne quand la clôture précède son début', () async {
      final int id = await seedRent(startDay: 5);
      final ExpenseModel future = expenseOf(
        id,
      ).copyWith(startDate: DateTime(2026, 9, 5));
      app.expenses.update(future);

      await app.container
          .read(expenseProvider.notifier)
          .deleteExpense(id, scope: RecurringDeletion.includingThisMonth);

      expect(app.expenses.table.get(id), isNull);
    });

    test(
      'garde l\'historique tant qu\'un maillon de la chaîne survit',
      () async {
        final int id = await seedRent();
        await app.container
            .read(expenseProvider.notifier)
            .updateExpense(
              expenseOf(id).copyWith(categorySlug: 'logement.charges'),
            );
        await app.container
            .read(expenseProvider.notifier)
            .updateExpense(expenseOf(id).copyWith(amount: 950));
        final ExpenseModel fork = app.expenses.table.all.firstWhere(
          (ExpenseModel row) => row.id != id,
        );

        await app.container
            .read(expenseProvider.notifier)
            .deletePermanently(fork.id);

        expect(eventsOf(id), hasLength(1));
      },
    );

    test('oublie l\'historique quand la chaîne entière disparaît', () async {
      final int id = await seedRent();
      await app.container
          .read(expenseProvider.notifier)
          .updateExpense(
            expenseOf(id).copyWith(categorySlug: 'logement.charges'),
          );
      await app.container
          .read(expenseProvider.notifier)
          .updateExpense(expenseOf(id).copyWith(amount: 950));
      final ExpenseModel fork = app.expenses.table.all.firstWhere(
        (ExpenseModel row) => row.id != id,
      );

      await app.container
          .read(expenseProvider.notifier)
          .deletePermanently(fork.id);
      await app.container.read(expenseProvider.notifier).deletePermanently(id);

      expect(eventsOf(id), isEmpty);
    });
  });

  group('la recatégorisation', () {
    test('se propage à toute la chaîne, passé compris', () async {
      final int id = await seedRent();
      await app.container
          .read(expenseProvider.notifier)
          .updateExpense(expenseOf(id).copyWith(amount: 950));

      await app.container
          .read(expenseProvider.notifier)
          .updateExpense(
            app.expenses.table.all
                .firstWhere((ExpenseModel row) => row.id != id)
                .copyWith(categorySlug: 'logement.charges'),
          );

      expect(
        app.expenses.table.all.map((ExpenseModel row) => row.categorySlug),
        everyElement('logement.charges'),
      );
    });
  });

  group('l\'ordre de la liste', () {
    test('classe les mensuelles par jour de prélèvement', () async {
      for (final int day in <int>[20, 3, 12]) {
        await app.container
            .read(expenseProvider.notifier)
            .addExpense(
              ExpenseModel.create(
                name: 'Charge $day',
                amount: 10,
                categorySlug: 'logement.charges',
                startDate: DateTime(2026, 1, day),
                frequency: Frequency.monthly,
                accountId: 1,
              ),
            );
      }

      final List<ExpenseModel> active = await app.container.read(
        expenseProvider.future,
      );

      expect(active.map((ExpenseModel e) => e.startDate.day), <int>[3, 12, 20]);
    });
  });
}
