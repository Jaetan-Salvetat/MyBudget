import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/entities/filterable_transaction.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/services/transaction_filter_service.dart';
import 'package:mybudget/models/transaction_filter_data.dart';

class _Transaction implements FilterableTransaction {
  @override
  final String name;
  @override
  final double amount;
  @override
  final int accountId;
  @override
  final int? beneficiaryId;
  @override
  final String? categorySlug;
  @override
  final Frequency frequencyEnum;
  @override
  final DateTime startDate;
  @override
  DateTime? get endDate => null;

  _Transaction({
    this.name = 'Loyer',
    this.amount = 500,
    this.accountId = 1,
    this.beneficiaryId,
    this.categorySlug,
    this.frequencyEnum = Frequency.monthly,
    DateTime? startDate,
  }) : startDate = startDate ?? DateTime(2026, 1, 12);
}

void main() {
  bool matches(
    TransactionFilterData filter, {
    _Transaction? transaction,
    String? groupKey,
  }) {
    return TransactionFilterService.matches(
      transaction ?? _Transaction(),
      filter,
      groupKey: groupKey,
    );
  }

  group('TransactionFilterService.matches', () {
    test('keeps everything when the filter is empty', () {
      expect(matches(const TransactionFilterData()), isTrue);
    });

    test('matches the search query on the name, ignoring case', () {
      expect(matches(const TransactionFilterData(searchQuery: 'loy')), isTrue);
      expect(matches(const TransactionFilterData(searchQuery: 'LOY')), isTrue);
      expect(matches(const TransactionFilterData(searchQuery: 'edf')), isFalse);
    });

    test('rejects an amount outside the bounds', () {
      expect(matches(const TransactionFilterData(minAmount: 600)), isFalse);
      expect(matches(const TransactionFilterData(maxAmount: 400)), isFalse);
      expect(
        matches(
          const TransactionFilterData(maxAmount: 600),
          transaction: _Transaction(amount: 900),
        ),
        isFalse,
      );
      expect(
        matches(const TransactionFilterData(minAmount: 400, maxAmount: 600)),
        isTrue,
      );
    });

    test('keeps an amount sitting exactly on a bound', () {
      expect(
        matches(const TransactionFilterData(minAmount: 500, maxAmount: 500)),
        isTrue,
      );
    });

    test('filters on the resolved category group key', () {
      const filter = TransactionFilterData(groupKeys: ['logement']);

      expect(matches(filter, groupKey: 'logement'), isTrue);
      expect(matches(filter, groupKey: 'alimentation'), isFalse);
      expect(matches(filter, groupKey: null), isFalse);
    });

    test('filters on the account', () {
      const filter = TransactionFilterData(accountIds: [2]);

      expect(matches(filter), isFalse);
      expect(matches(filter, transaction: _Transaction(accountId: 2)), isTrue);
    });

    test('filters on the beneficiary', () {
      const filter = TransactionFilterData(beneficiaryIds: [7]);

      expect(matches(filter), isFalse);
      expect(
        matches(filter, transaction: _Transaction(beneficiaryId: 7)),
        isTrue,
      );
    });

    test('filters on the frequency', () {
      const filter = TransactionFilterData(types: [Frequency.oneTime]);

      expect(matches(filter), isFalse);
      expect(
        matches(
          filter,
          transaction: _Transaction(frequencyEnum: Frequency.oneTime),
        ),
        isTrue,
      );
    });

    test('requires every criterion at once', () {
      const filter = TransactionFilterData(
        minAmount: 100,
        accountIds: [1],
        types: [Frequency.monthly],
      );

      expect(matches(filter), isTrue);
      expect(matches(filter, transaction: _Transaction(accountId: 9)), isFalse);
    });
  });

  group('TransactionFilterService.apply', () {
    test('keeps only the transactions matching the filter', () {
      final transactions = [
        _Transaction(name: 'Loyer', categorySlug: 'rent'),
        _Transaction(name: 'Courses', categorySlug: 'food'),
      ];

      final kept = TransactionFilterService.apply(
        transactions,
        const TransactionFilterData(groupKeys: ['logement']),
        groupKeyOf: (transaction) =>
            transaction.categorySlug == 'rent' ? 'logement' : 'alimentation',
      );

      expect(kept.map((t) => t.name), ['Loyer']);
    });
  });
}
