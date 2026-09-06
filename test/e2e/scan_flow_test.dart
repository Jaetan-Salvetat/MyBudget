import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/receipt_scan_result_model.dart';
import 'package:mybudget/models/scanned_item_model.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/scan/scan_provider.dart';

import 'harness/e2e_harness.dart';

void main() {
  late E2EHarness app;
  late int accountId;

  final DateTime now = E2EHarness.defaultNow;
  final Uint8List photo = Uint8List.fromList(<int>[1, 2, 3]);

  setUp(() async {
    app = await E2EHarness.start(now: now);
    accountId = app.accounts.add(
      AccountModel.create(name: 'Courant', bank: 'Boursorama'),
    );
    app.container.listen(scanProvider, (_, _) {}, fireImmediately: true);
  });

  tearDown(() => app.dispose());

  ScanNotifier scan() => app.container.read(scanProvider.notifier);

  ReceiptScanResultModel? current() => app.container.read(scanProvider).value;

  ScannedItemModel item({
    required String name,
    required double amount,
    String? slug = 'alimentation.courses',
    String? label = 'Courses',
    double discount = 0,
    double confidence = 0.9,
  }) {
    return ScannedItemModel(
      name: name,
      amount: amount,
      discount: discount,
      categorySlug: slug,
      categoryName: label,
      categoryConfidence: confidence,
    );
  }

  Future<void> readReceipt({
    String? store = 'Carrefour',
    List<ScannedItemModel>? items,
    double? printedTotal,
  }) async {
    app.scriptReceipt(
      ReceiptScanResultModel(
        date: DateTime(2026, 6, 12),
        storeName: store,
        printedTotal: printedTotal,
        items:
            items ??
            <ScannedItemModel>[
              item(name: 'Pain', amount: 2.5),
              item(name: 'Lait', amount: 1.2),
            ],
      ),
    );
    await scan().scanReceipt(photo);
  }

  group('la lecture d\'un ticket', () {
    test('livre les articles et l\'enseigne', () async {
      await readReceipt();

      expect(current()!.storeName, 'Carrefour');
      expect(current()!.items.map((ScannedItemModel i) => i.name), <String>[
        'Pain',
        'Lait',
      ]);
    });

    test('additionne les articles', () async {
      await readReceipt();

      expect(current()!.itemsTotal, closeTo(3.7, 0.001));
    });

    test('signale l\'écart avec le total imprimé', () async {
      await readReceipt(printedTotal: 5.0);

      expect(current()!.gap, closeTo(1.3, 0.001));
    });

    test('une lecture impossible laisse une erreur, pas un ticket', () async {
      app.scriptReceipt(ReceiptScanResultModel(date: now, items: const []));
      app.scanner.failWith(StateError('photo illisible'));

      await scan().scanReceipt(photo);

      expect(
        app.container.read(scanProvider),
        isA<AsyncError<ReceiptScanResultModel?>>(),
      );
      expect(current(), isNull);
    });
  });

  group('la relecture avant validation', () {
    test('une remise réduit le montant effectif', () async {
      await readReceipt();

      scan().updateItemDiscount(0, 0.5);

      expect(current()!.items.first.effectiveAmount, closeTo(2.0, 0.001));
    });

    test('corrige la date du ticket', () async {
      await readReceipt();

      scan().updateDate(DateTime(2026, 6, 10));

      expect(current()!.date, DateTime(2026, 6, 10));
    });

    test('une modification hors bornes ne casse rien', () async {
      await readReceipt();

      scan().updateItemAmount(99, 10);

      expect(current()!.items, hasLength(2));
    });
  });

  group('la validation', () {
    test('crée une dépense par catégorie, pas par article', () async {
      await readReceipt(
        items: <ScannedItemModel>[
          item(name: 'Pain', amount: 2.5),
          item(name: 'Lait', amount: 1.2),
          item(
            name: 'Éponge',
            amount: 3.0,
            slug: 'logement.services',
            label: 'Services',
          ),
        ],
      );

      await scan().validateAndCreate(accountId, photo);

      final List<ExpenseModel> created = app.expenses.getAll();
      expect(created, hasLength(2));
      expect(created.map((ExpenseModel e) => e.categorySlug).toSet(), <String>{
        'alimentation.courses',
        'logement.services',
      });
    });

    test('somme les articles d\'une même catégorie', () async {
      await readReceipt();

      await scan().validateAndCreate(accountId, photo);

      expect(app.expenses.getAll().single.amount, closeTo(3.7, 0.001));
    });

    test('nomme la dépense d\'après l\'enseigne et la famille', () async {
      await readReceipt();

      await scan().validateAndCreate(accountId, photo);

      expect(app.expenses.getAll().single.name, 'Carrefour — Courses');
    });

    test('se rabat sur la date quand l\'enseigne manque', () async {
      await readReceipt(store: null);

      await scan().validateAndCreate(accountId, photo);

      expect(app.expenses.getAll().single.name, startsWith('Ticket du '));
    });

    test('date les dépenses du jour du ticket, pas du jour du scan', () async {
      await readReceipt();

      await scan().validateAndCreate(accountId, photo);

      expect(app.expenses.getAll().single.startDate, DateTime(2026, 6, 12));
    });

    test('rattache les dépenses au compte choisi et à la photo', () async {
      await readReceipt();

      await scan().validateAndCreate(accountId, photo);

      final ExpenseModel created = app.expenses.getAll().single;
      expect(created.accountId, accountId);
      expect(created.receiptPath, isNotNull);
    });

    test('ignore les articles sans catégorie', () async {
      await readReceipt(
        items: <ScannedItemModel>[
          item(name: 'Pain', amount: 2.5),
          item(name: 'Inconnu', amount: 9.0, slug: null, label: null),
        ],
      );

      await scan().validateAndCreate(accountId, photo);

      expect(app.expenses.getAll(), hasLength(1));
      expect(app.expenses.getAll().single.amount, closeTo(2.5, 0.001));
    });

    test('sans ticket lu, ne crée rien', () async {
      final List<int> created = await scan().validateAndCreate(
        accountId,
        photo,
      );

      expect(created, isEmpty);
      expect(app.expenses.getAll(), isEmpty);
    });
  });

  group('l\'annulation après validation', () {
    test('retire toutes les dépenses créées', () async {
      await readReceipt(
        items: <ScannedItemModel>[
          item(name: 'Pain', amount: 2.5),
          item(
            name: 'Éponge',
            amount: 3.0,
            slug: 'logement.services',
            label: 'Services',
          ),
        ],
      );
      final List<int> created = await scan().validateAndCreate(
        accountId,
        photo,
      );

      await scan().discardCreated(created);

      expect(app.expenses.getAll(), isEmpty);
      expect(await app.container.read(expenseProvider.future), isEmpty);
    });
  });

  group('la remise à zéro', () {
    test('vide le ticket en cours', () async {
      await readReceipt();

      scan().reset();

      expect(current(), isNull);
    });
  });
}
