import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/transaction_change.dart';
import 'package:mybudget/core/services/transaction_change_service.dart';
import 'package:mybudget/models/expense_model.dart';

void main() {
  final at = DateTime(2026, 6, 20);

  ExpenseModel expense({
    String name = 'Loyer',
    double amount = 800,
    String? categorySlug = 'logement.loyer',
    String frequency = 'Mensuel',
    int accountId = 1,
    int? beneficiaryId,
  }) {
    return ExpenseModel.create(
      name: name,
      amount: amount,
      categorySlug: categorySlug,
      startDate: DateTime(2026, 1, 10),
      frequency: frequency,
      accountId: accountId,
      beneficiaryId: beneficiaryId,
    );
  }

  group('an edit applied in place', () {
    test('records nothing when nothing moved', () {
      final changes = TransactionChangeService.inPlaceChanges(
        expense(),
        expense(),
        at: at,
        forked: false,
      );

      expect(changes, isEmpty);
    });

    test('records the new price', () {
      final changes = TransactionChangeService.inPlaceChanges(
        expense(),
        expense(amount: 900),
        at: at,
        forked: false,
      );

      expect(changes.single.change, TransactionChange.amount);
      expect(changes.single.from, '800.0');
      expect(changes.single.to, '900.0');
      expect(changes.single.at, at);
    });

    test('records the new category', () {
      final changes = TransactionChangeService.inPlaceChanges(
        expense(),
        expense(categorySlug: 'logement.charges'),
        at: at,
        forked: false,
      );

      expect(changes.single.change, TransactionChange.category);
      expect(changes.single.from, 'logement.loyer');
      expect(changes.single.to, 'logement.charges');
    });

    test('records a category that was missing', () {
      final changes = TransactionChangeService.inPlaceChanges(
        expense(categorySlug: null),
        expense(),
        at: at,
        forked: false,
      );

      expect(changes.single.change, TransactionChange.category);
      expect(changes.single.from, isNull);
      expect(changes.single.to, 'logement.loyer');
    });

    test('records every field that moved at once', () {
      final changes = TransactionChangeService.inPlaceChanges(
        expense(),
        expense(
          name: 'Loyer appart',
          amount: 900,
          frequency: 'Annuel',
          accountId: 2,
          beneficiaryId: 3,
        ),
        at: at,
        forked: false,
      );

      expect(
        changes.map((change) => change.change),
        containsAll(<TransactionChange>[
          TransactionChange.name,
          TransactionChange.amount,
          TransactionChange.frequency,
          TransactionChange.account,
          TransactionChange.beneficiary,
        ]),
      );
    });
  });

  group('an edit that forks the chain', () {
    test('leaves the terms to the chain and keeps the category', () {
      final changes = TransactionChangeService.inPlaceChanges(
        expense(),
        expense(amount: 900, categorySlug: 'logement.charges'),
        at: at,
        forked: true,
      );

      expect(changes.single.change, TransactionChange.category);
    });

    test('records nothing when only the terms moved', () {
      final changes = TransactionChangeService.inPlaceChanges(
        expense(),
        expense(amount: 900),
        at: at,
        forked: true,
      );

      expect(changes, isEmpty);
    });
  });
}
