import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/data/model/account_model.dart';
import 'package:mybudget/data/model/expense_model.dart';
import 'package:mybudget/data/model/revenue_model.dart';
import 'package:mybudget/data/model/transfer_model.dart';
import 'package:mybudget/data/provider/accounts_provider.dart';
import 'package:mybudget/data/provider/expenses_provider.dart';
import 'package:mybudget/data/provider/revenues_provider.dart';
import 'package:mybudget/data/provider/transfers_provider.dart';

import 'harness/e2e_harness.dart';

void main() {
  late E2EHarness app;
  late int courant;
  late int livret;

  setUp(() async {
    app = await E2EHarness.start();
    courant = app.accounts.add(
      AccountModel.create(name: 'Courant', bank: 'Boursorama'),
    );
    livret = app.accounts.add(
      AccountModel.create(name: 'Livret', bank: 'Boursorama'),
    );
  });

  tearDown(() => app.dispose());

  Future<void> addTransfer({
    required double amount,
    required int from,
    required int to,
    Frequency frequency = Frequency.monthly,
    DateTime? startDate,
    String name = 'Épargne',
  }) {
    return app.container
        .read(transferProvider.notifier)
        .addTransfer(
          TransferModel.create(
            name: name,
            amount: amount,
            fromAccountId: from,
            toAccountId: to,
            startDate: startDate ?? DateTime(2026, 1, 5),
            frequency: frequency,
          ),
        );
  }

  Future<double> balanceOf(int accountId) async {
    app.container.read(accountProvider);
    return app.container
        .read(accountProvider.notifier)
        .getAccountBalance(accountId);
  }

  group('un virement récurrent', () {
    test('sort du compte source et entre sur le compte cible', () async {
      await addTransfer(amount: 300, from: courant, to: livret);

      expect(await balanceOf(courant), -300);
      expect(await balanceOf(livret), 300);
    });

    test('laisse la somme des deux soldes inchangée', () async {
      await addTransfer(amount: 300, from: courant, to: livret);

      expect(await balanceOf(courant) + await balanceOf(livret), 0);
    });

    test('annuel compte pour un douzième par mois', () async {
      await addTransfer(
        amount: 1200,
        from: courant,
        to: livret,
        frequency: Frequency.annual,
      );

      expect(await balanceOf(livret), 100);
    });

    test('ponctuel ne pèse pas sur le solde mensuel', () async {
      await addTransfer(
        amount: 500,
        from: courant,
        to: livret,
        frequency: Frequency.oneTime,
      );

      expect(await balanceOf(courant), 0);
      expect(await balanceOf(livret), 0);
    });
  });

  group('la modification d\'un virement récurrent', () {
    test('renommer seul ne scinde pas et renomme la chaîne', () async {
      await addTransfer(amount: 300, from: courant, to: livret);
      final TransferModel existing = app.transfers.table.all.single;

      await app.container
          .read(transferProvider.notifier)
          .updateTransfer(existing.copyWith(name: 'Épargne projet'));

      expect(app.transfers.table.all, hasLength(1));
      expect(app.transfers.table.all.single.name, 'Épargne projet');
    });

    test('changer le montant scinde la série au mois suivant', () async {
      await addTransfer(amount: 300, from: courant, to: livret);
      final TransferModel existing = app.transfers.table.all.single;

      await app.container
          .read(transferProvider.notifier)
          .updateTransfer(existing.copyWith(amount: 400));

      final TransferModel closed = app.transfers.table.get(existing.id)!;
      final TransferModel fork = app.transfers.table.all.firstWhere(
        (TransferModel row) => row.id != existing.id,
      );

      expect(closed.endDate, DateTime(2026, 7, 4));
      expect(fork.amount, 400);
      expect(fork.startDate, DateTime(2026, 7, 5));
      expect(fork.parentId, existing.id);
    });

    test('seul le montant en vigueur pèse sur le solde', () async {
      await addTransfer(amount: 300, from: courant, to: livret);
      final TransferModel existing = app.transfers.table.all.single;

      await app.container
          .read(transferProvider.notifier)
          .updateTransfer(existing.copyWith(amount: 400));

      expect(await balanceOf(livret), 400);
    });
  });

  group('la suppression d\'un virement', () {
    test('récurrent déjà commencé : il se clôt aujourd\'hui', () async {
      await addTransfer(amount: 300, from: courant, to: livret);
      final int id = app.transfers.table.all.single.id;

      await app.container.read(transferProvider.notifier).deleteTransfer(id);

      expect(app.transfers.table.get(id)!.endDate, DateTime(2026, 6, 15));
      expect(await balanceOf(livret), 0);
    });

    test('pas encore commencé : il disparaît', () async {
      await addTransfer(
        amount: 300,
        from: courant,
        to: livret,
        startDate: DateTime(2026, 9, 5),
      );
      final int id = app.transfers.table.all.single.id;

      await app.container.read(transferProvider.notifier).deleteTransfer(id);

      expect(app.transfers.table.get(id), isNull);
    });
  });

  group('le solde d\'un compte', () {
    test('vaut revenus moins dépenses plus virements', () async {
      await app.container
          .read(revenueProvider.notifier)
          .addRevenue(
            RevenueModel.create(
              name: 'Salaire',
              amount: 2400,
              startDate: DateTime(2026, 1, 5),
              frequency: Frequency.monthly,
              accountId: courant,
              categorySlug: 'salaire.salaire_net',
            ),
          );
      await app.container
          .read(expenseProvider.notifier)
          .addExpense(
            ExpenseModel.create(
              name: 'Loyer',
              amount: 900,
              categorySlug: 'logement.loyer',
              startDate: DateTime(2026, 1, 5),
              frequency: Frequency.monthly,
              accountId: courant,
            ),
          );
      await addTransfer(amount: 300, from: courant, to: livret);

      expect(await balanceOf(courant), 2400 - 900 - 300);
    });

    test('ignore ce qui appartient à un autre compte', () async {
      await app.container
          .read(expenseProvider.notifier)
          .addExpense(
            ExpenseModel.create(
              name: 'Loyer',
              amount: 900,
              categorySlug: 'logement.loyer',
              startDate: DateTime(2026, 1, 5),
              frequency: Frequency.monthly,
              accountId: courant,
            ),
          );

      expect(await balanceOf(livret), 0);
    });

    test('cesse de compter une dépense clôturée', () async {
      final int id = await app.container
          .read(expenseProvider.notifier)
          .addExpense(
            ExpenseModel.create(
              name: 'Salle de sport',
              amount: 40,
              categorySlug: 'loisirs.sport',
              startDate: DateTime(2026, 1, 5),
              frequency: Frequency.monthly,
              accountId: courant,
            ),
          );
      expect(await balanceOf(courant), -40);

      await app.container.read(expenseProvider.notifier).deleteExpense(id);

      expect(await balanceOf(courant), 0);
    });
  });
}
