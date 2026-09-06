import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_change.dart';
import 'package:mybudget/core/services/transaction_change_service.dart';
import 'package:mybudget/models/expense_model.dart';

void main() {
  final at = DateTime(2026, 6, 20);

  ExpenseModel expense({
    String name = 'Loyer',
    double amount = 800,
    String? categorySlug = 'logement.loyer',
    Frequency frequency = Frequency.monthly,
    int accountId = 1,
    int? beneficiaryId,
    DateTime? startDate,
  }) {
    return ExpenseModel.create(
      name: name,
      amount: amount,
      categorySlug: categorySlug,
      startDate: startDate ?? DateTime(2026, 1, 10),
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
          frequency: Frequency.annual,
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

  group('the terms of a rule', () {
    test('are untouched when nothing but the category moved', () {
      expect(
        TransactionChangeService.changesTerms(
          expense(),
          expense(categorySlug: 'logement.charges'),
        ),
        isFalse,
      );
    });

    test('are untouched when only the month it is read from moved', () {
      expect(
        TransactionChangeService.changesTerms(
          expense(startDate: DateTime(2026, 1, 10)),
          expense(startDate: DateTime(2026, 5, 10)),
        ),
        isFalse,
      );
    });

    test('move with the price', () {
      expect(
        TransactionChangeService.changesTerms(expense(), expense(amount: 900)),
        isTrue,
      );
    });

    test('move with the name', () {
      expect(
        TransactionChangeService.changesTerms(
          expense(),
          expense(name: 'Loyer parking'),
        ),
        isTrue,
      );
    });

    test('move with the account', () {
      expect(
        TransactionChangeService.changesTerms(expense(), expense(accountId: 2)),
        isTrue,
      );
    });

    test('move with the beneficiary', () {
      expect(
        TransactionChangeService.changesTerms(
          expense(),
          expense(beneficiaryId: 4),
        ),
        isTrue,
      );
    });

    test('move with the frequency', () {
      expect(
        TransactionChangeService.changesTerms(
          expense(),
          expense(frequency: Frequency.annual),
        ),
        isTrue,
      );
    });

    test('move with the day of the month it falls on', () {
      expect(
        TransactionChangeService.changesTerms(
          expense(startDate: DateTime(2026, 1, 10)),
          expense(startDate: DateTime(2026, 1, 20)),
        ),
        isTrue,
      );
    });

    test('move with the month a yearly rule falls on', () {
      expect(
        TransactionChangeService.changesTerms(
          expense(
            frequency: Frequency.annual,
            startDate: DateTime(2026, 1, 10),
          ),
          expense(
            frequency: Frequency.annual,
            startDate: DateTime(2026, 3, 10),
          ),
        ),
        isTrue,
      );
    });

    test('leave a yearly rule alone when only its year moved', () {
      expect(
        TransactionChangeService.changesTerms(
          expense(
            frequency: Frequency.annual,
            startDate: DateTime(2026, 1, 10),
          ),
          expense(
            frequency: Frequency.annual,
            startDate: DateTime(2027, 1, 10),
          ),
        ),
        isFalse,
      );
    });

    test('move with the date of a one-off', () {
      expect(
        TransactionChangeService.changesTerms(
          expense(
            frequency: Frequency.oneTime,
            startDate: DateTime(2026, 1, 10),
          ),
          expense(
            frequency: Frequency.oneTime,
            startDate: DateTime(2026, 2, 10),
          ),
        ),
        isTrue,
      );
    });
  });
}
