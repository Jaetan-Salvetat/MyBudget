import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/data/model/transaction_filter_data.dart';

void main() {
  group('TransactionFilterData', () {
    test('a fresh filter is empty and counts nothing', () {
      const filter = TransactionFilterData();

      expect(filter.isEmpty, isTrue);
      expect(filter.activeCount, 0);
    });

    test('a category selection makes the filter active', () {
      const filter = TransactionFilterData(groupKeys: ['salaire']);

      expect(filter.isEmpty, isFalse);
      expect(filter.activeCount, 1);
    });

    test('counts each active criterion once', () {
      const filter = TransactionFilterData(
        minAmount: 100,
        maxAmount: 900,
        groupKeys: ['salaire', 'transfert'],
        accountIds: [1],
        beneficiaryIds: [2],
        types: [Frequency.monthly],
      );

      expect(filter.activeCount, 5);
    });

    test('a search query alone does not count as a filter', () {
      const filter = TransactionFilterData(searchQuery: 'salaire');

      expect(filter.isEmpty, isFalse);
      expect(filter.activeCount, 0);
    });

    test('an empty search query leaves the filter empty', () {
      const filter = TransactionFilterData(searchQuery: '');

      expect(filter.isEmpty, isTrue);
    });

    test('copyWith replaces only the given criteria', () {
      const filter = TransactionFilterData(
        minAmount: 10,
        groupKeys: ['logement'],
        types: [Frequency.monthly],
      );

      final updated = filter.copyWith(groupKeys: const ['alimentation']);

      expect(updated.groupKeys, ['alimentation']);
      expect(updated.minAmount, 10);
      expect(updated.types, [Frequency.monthly]);
    });

    test('clearAmounts drops both bounds and keeps the rest', () {
      const filter = TransactionFilterData(
        minAmount: 10,
        maxAmount: 900,
        groupKeys: ['logement'],
        searchQuery: 'loyer',
      );

      final cleared = filter.clearAmounts();

      expect(cleared.minAmount, isNull);
      expect(cleared.maxAmount, isNull);
      expect(cleared.groupKeys, ['logement']);
      expect(cleared.searchQuery, 'loyer');
    });
  });
}
