import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/effective_month.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/recurring_deletion.dart';
import 'package:mybudget/core/enums/transaction_change.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/data/model/revenue_model.dart';
import 'package:mybudget/data/model/transaction_event_model.dart';
import 'package:mybudget/data/provider/revenues_provider.dart';

import 'harness/e2e_harness.dart';

void main() {
  late E2EHarness app;

  setUp(() async {
    app = await E2EHarness.start();
  });

  tearDown(() => app.dispose());

  Future<int> seedSalary({
    double amount = 2400,
    int startDay = 5,
    Frequency frequency = Frequency.monthly,
  }) async {
    return app.container
        .read(revenueProvider.notifier)
        .addRevenue(
          RevenueModel.create(
            name: 'Salaire',
            amount: amount,
            startDate: DateTime(2026, 1, startDay),
            frequency: frequency,
            accountId: 1,
            categorySlug: 'salaire.salaire_net',
          ),
        );
  }

  RevenueModel revenueOf(int id) => app.revenues.table.get(id)!;

  List<TransactionEventModel> eventsOf(int rootId) =>
      app.transactionEvents.getForRoot(rootId, TransactionType.income);

  group('un revenu mensuel dont les termes changent', () {
    test('se scinde comme une dépense, la veille de la nouvelle', () async {
      final int id = await seedSalary();

      await app.container
          .read(revenueProvider.notifier)
          .updateRevenue(
            revenueOf(id).copyWith(amount: 2600),
            effectiveMonth: EffectiveMonth.thisMonth,
          );

      final RevenueModel fork = app.revenues.table.all.firstWhere(
        (RevenueModel row) => row.id != id,
      );

      expect(revenueOf(id).amount, 2400);
      expect(revenueOf(id).endDate, DateTime(2026, 6, 4));
      expect(fork.amount, 2600);
      expect(fork.startDate, DateTime(2026, 6, 5));
      expect(fork.parentId, id);
    });

    test('reporte la scission au mois suivant quand on le demande', () async {
      final int id = await seedSalary();

      await app.container
          .read(revenueProvider.notifier)
          .updateRevenue(
            revenueOf(id).copyWith(amount: 2600),
            effectiveMonth: EffectiveMonth.nextMonth,
          );

      expect(revenueOf(id).endDate, DateTime(2026, 7, 4));
      expect(
        app.revenues.table.all
            .firstWhere((RevenueModel row) => row.id != id)
            .startDate,
        DateTime(2026, 7, 5),
      );
    });

    test('n\'expose que la version en vigueur', () async {
      final int id = await seedSalary();

      await app.container
          .read(revenueProvider.notifier)
          .updateRevenue(revenueOf(id).copyWith(amount: 2600));

      final List<RevenueModel> active = await app.container.read(
        revenueProvider.future,
      );

      expect(active.map((RevenueModel r) => r.amount), <double>[2600]);
    });
  });

  group('un revenu dont seule la catégorie change', () {
    test('reste en place et consigne le changement', () async {
      final int id = await seedSalary();

      await app.container
          .read(revenueProvider.notifier)
          .updateRevenue(revenueOf(id).copyWith(categorySlug: 'salaire.prime'));

      final List<TransactionEventModel> events = eventsOf(id);

      expect(app.revenues.table.all, hasLength(1));
      expect(events, hasLength(1));
      expect(events.single.changeEnum, TransactionChange.category);
      expect(events.single.nextValue, 'salaire.prime');
    });

    test('n\'écrit pas dans l\'historique des dépenses', () async {
      final int id = await seedSalary();

      await app.container
          .read(revenueProvider.notifier)
          .updateRevenue(revenueOf(id).copyWith(categorySlug: 'salaire.prime'));

      expect(
        app.transactionEvents.getForRoot(id, TransactionType.expense),
        isEmpty,
      );
    });
  });

  group('la suppression d\'un revenu mensuel', () {
    test('« à partir du mois prochain » le clôt aujourd\'hui', () async {
      final int id = await seedSalary();

      await app.container.read(revenueProvider.notifier).deleteRevenue(id);

      expect(revenueOf(id).endDate, DateTime(2026, 6, 15));
      expect(await app.container.read(revenueProvider.future), isEmpty);
    });

    test('« dès ce mois-ci » le clôt la veille de l\'échéance', () async {
      final int id = await seedSalary();

      await app.container
          .read(revenueProvider.notifier)
          .deleteRevenue(id, scope: RecurringDeletion.includingThisMonth);

      expect(revenueOf(id).endDate, DateTime(2026, 6, 4));
    });

    test('efface un revenu ponctuel sans le clore', () async {
      final int id = await seedSalary(frequency: Frequency.oneTime);

      await app.container.read(revenueProvider.notifier).deleteRevenue(id);

      expect(app.revenues.table.get(id), isNull);
    });
  });

  group('la recatégorisation', () {
    test('se propage à toute la chaîne', () async {
      final int id = await seedSalary();
      await app.container
          .read(revenueProvider.notifier)
          .updateRevenue(revenueOf(id).copyWith(amount: 2600));

      await app.container
          .read(revenueProvider.notifier)
          .updateRevenue(
            app.revenues.table.all
                .firstWhere((RevenueModel row) => row.id != id)
                .copyWith(categorySlug: 'salaire.prime'),
          );

      expect(
        app.revenues.table.all.map((RevenueModel row) => row.categorySlug),
        everyElement('salaire.prime'),
      );
    });
  });
}
