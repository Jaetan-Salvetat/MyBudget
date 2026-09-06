import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/data/model/account_model.dart';
import 'package:mybudget/data/model/beneficiary_model.dart';
import 'package:mybudget/data/model/category_memory_model.dart';
import 'package:mybudget/data/model/category_override_model.dart';
import 'package:mybudget/data/model/expense_model.dart';
import 'package:mybudget/data/model/revenue_model.dart';
import 'package:mybudget/data/model/transfer_model.dart';
import 'package:mybudget/data/service/data/import_report.dart';
import 'package:mybudget/ui/settings/data_provider.dart';

import 'harness/e2e_harness.dart';

void main() {
  late E2EHarness app;

  final DateTime now = E2EHarness.defaultNow;

  setUp(() async {
    app = await E2EHarness.start(now: now);
  });

  tearDown(() => app.dispose());

  DataNotifier data() => app.container.read(dataProvider.notifier);

  void seedEverything() {
    final int courant = app.accounts.add(
      AccountModel.create(name: 'Courant', bank: 'Boursorama'),
    );
    final int livret = app.accounts.add(
      AccountModel.create(name: 'Livret', bank: 'Boursorama'),
    );
    final int landlord = app.beneficiaries.add(
      BeneficiaryModel.create(name: 'Agence', color: 3),
    );

    app.expenses.add(
      ExpenseModel.create(
        name: 'Loyer',
        amount: 900,
        categorySlug: 'logement.loyer',
        startDate: DateTime(2026, 1, 5),
        frequency: Frequency.monthly,
        accountId: courant,
        beneficiaryId: landlord,
      ),
    );
    app.revenues.add(
      RevenueModel.create(
        name: 'Salaire',
        amount: 2400,
        startDate: DateTime(2026, 1, 3),
        frequency: Frequency.monthly,
        accountId: courant,
        categorySlug: 'salaire.salaire_net',
      ),
    );
    app.transfers.add(
      TransferModel.create(
        name: 'Épargne',
        amount: 300,
        fromAccountId: courant,
        toAccountId: livret,
        startDate: DateTime(2026, 1, 10),
        frequency: Frequency.monthly,
      ),
    );
    app.categoryOverrides.save(
      CategoryOverrideModel.create(
        slug: 'logement.loyer',
        name: 'Toit',
        icon: 'home',
        color: 0xFF00FF00,
      ),
    );
    app.categoryMemory.put(
      CategoryMemoryModel.create(
        key: 'monoprix',
        slug: 'alimentation.courses',
        updatedAt: now,
      ),
    );
  }

  const Set<String> identityKeys = <String>{
    'id',
    'accountId',
    'beneficiaryId',
    'parentId',
    'fromAccountId',
    'toAccountId',
  };

  List<Map<String, Object?>> withoutIds(List<Map<String, dynamic>> rows) => [
    for (final Map<String, dynamic> row in rows)
      <String, Object?>{
        for (final MapEntry<String, dynamic> entry in row.entries)
          if (!identityKeys.contains(entry.key)) entry.key: entry.value,
      },
  ];

  Map<String, Object?> snapshot() => <String, Object?>{
    'accounts': withoutIds(
      app.accounts.getAll().map((AccountModel a) => a.toJson()).toList(),
    ),
    'beneficiaries': withoutIds(
      app.beneficiaries
          .getAll()
          .map((BeneficiaryModel b) => b.toJson())
          .toList(),
    ),
    'expenses': withoutIds(
      app.expenses.getAll().map((ExpenseModel e) => e.toJson()).toList(),
    ),
    'revenues': withoutIds(
      app.revenues.getAll().map((RevenueModel r) => r.toJson()).toList(),
    ),
    'transfers': withoutIds(
      app.transfers.getAll().map((TransferModel t) => t.toJson()).toList(),
    ),
    'overrides': withoutIds(
      app.categoryOverrides
          .getAll()
          .values
          .map((CategoryOverrideModel o) => o.toJson())
          .toList(),
    ),
    'memory': withoutIds(
      app.categoryMemory
          .getAll()
          .map((CategoryMemoryModel m) => m.toJson())
          .toList(),
    ),
  };

  Future<String> exportToJson() async {
    final String path = await data().exportUserData();
    return File(path).readAsString();
  }

  group('l\'export', () {
    test('écrit un fichier daté de l\'horloge injectée', () async {
      seedEverything();

      final String path = await data().exportUserData();

      expect(path, endsWith('mybudget_backup_2026-06-15.json'));
      expect(File(path).existsSync(), isTrue);
    });

    test('emporte chaque famille de données', () async {
      seedEverything();

      final Map<String, dynamic> backup =
          jsonDecode(await exportToJson()) as Map<String, dynamic>;

      expect(backup['accounts'], hasLength(2));
      expect(backup['beneficiaries'], hasLength(1));
      expect(backup['expenses'], hasLength(1));
      expect(backup['revenues'], hasLength(1));
      expect(backup['transfers'], hasLength(1));
      expect(backup['categoryOverrides'], hasLength(1));
      expect(backup['categoryMemory'], hasLength(1));
    });
  });

  group('le va-et-vient export puis import', () {
    test('restitue les données à l\'identique', () async {
      seedEverything();
      final Map<String, Object?> before = snapshot();
      final String backup = await exportToJson();

      await data().deleteAllUserData();
      expect(app.accounts.getAll(), isEmpty);

      await data().importUserData(backup);

      expect(app.container.read(dataProvider).error, isEmpty);
      expect(snapshot(), before);
    });

    test('rend un rapport sans avertissement', () async {
      seedEverything();
      final String backup = await exportToJson();
      await data().deleteAllUserData();

      await data().importUserData(backup);

      final ImportReport report = app.container
          .read(dataProvider)
          .importReport!;

      expect(report.hasWarnings, isFalse);
      expect(report.totalSkipped, 0);
      expect(report.totalImported, 7);
    });

    test('ne laisse pas d\'erreur dans l\'état', () async {
      seedEverything();
      final String backup = await exportToJson();
      await data().deleteAllUserData();

      await data().importUserData(backup);

      expect(app.container.read(dataProvider).error, isEmpty);
      expect(app.container.read(dataProvider).importProgress, 1.0);
    });

    test('recâble les liens entre dépense, compte et bénéficiaire', () async {
      seedEverything();
      final String backup = await exportToJson();
      await data().deleteAllUserData();

      await data().importUserData(backup);

      final ExpenseModel rent = app.expenses.getAll().single;
      final AccountModel courant = app.accounts.getAll().firstWhere(
        (AccountModel a) => a.name == 'Courant',
      );
      final BeneficiaryModel agency = app.beneficiaries.getAll().single;

      expect(rent.accountId, courant.id);
      expect(rent.beneficiaryId, agency.id);
    });

    test('recâble les deux extrémités d\'un virement', () async {
      seedEverything();
      final String backup = await exportToJson();
      await data().deleteAllUserData();

      await data().importUserData(backup);

      final TransferModel transfer = app.transfers.getAll().single;
      final AccountModel courant = app.accounts.getAll().firstWhere(
        (AccountModel a) => a.name == 'Courant',
      );
      final AccountModel livret = app.accounts.getAll().firstWhere(
        (AccountModel a) => a.name == 'Livret',
      );

      expect(transfer.fromAccountId, courant.id);
      expect(transfer.toAccountId, livret.id);
    });

    test('remplace les données au lieu de les cumuler', () async {
      seedEverything();
      final String backup = await exportToJson();

      await data().importUserData(backup);

      expect(app.accounts.getAll(), hasLength(2));
      expect(app.expenses.getAll(), hasLength(1));
    });
  });

  group('un contenu inexploitable', () {
    test('laisse un message d\'erreur sans vider les données', () async {
      seedEverything();

      await data().importUserData('ceci n\'est pas du json');

      expect(app.container.read(dataProvider).error, isNotEmpty);
      expect(app.accounts.getAll(), hasLength(2));
    });
  });

  group('l\'effacement total', () {
    test('vide toutes les familles de données', () async {
      seedEverything();

      await data().deleteAllUserData();

      expect(app.accounts.getAll(), isEmpty);
      expect(app.beneficiaries.getAll(), isEmpty);
      expect(app.expenses.getAll(), isEmpty);
      expect(app.revenues.getAll(), isEmpty);
      expect(app.transfers.getAll(), isEmpty);
      expect(app.categoryOverrides.getAll(), isEmpty);
      expect(app.categoryMemory.getAll(), isEmpty);
      expect(app.loans.getAll(), isEmpty);
      expect(app.loanEvents.getAll(), isEmpty);
      expect(app.transactionEvents.table.all, isEmpty);
      expect(app.legacyCategories.namesById(), isEmpty);
    });
  });
}
