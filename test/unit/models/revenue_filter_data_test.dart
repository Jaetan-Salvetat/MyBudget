import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/models/revenue_filter_data.dart';

void main() {
  test('a fresh filter is empty and counts nothing', () {
    final filter = RevenueFilterData();

    expect(filter.isEmpty, isTrue);
    expect(filter.activeCount, 0);
  });

  test('a category selection makes the filter active', () {
    final filter = RevenueFilterData(categoryGroupKeys: const ['salaire']);

    expect(filter.isEmpty, isFalse);
    expect(filter.activeCount, 1);
  });

  test('counts each active criterion once', () {
    final filter = RevenueFilterData(
      minAmount: 100,
      maxAmount: 900,
      accountIds: const [1],
      beneficiaryIds: const [2],
      frequencies: const ['Mensuel'],
      categoryGroupKeys: const ['salaire', 'transfert'],
    );

    expect(filter.activeCount, 5);
  });

  test('a search query alone does not count as a filter', () {
    final filter = RevenueFilterData(searchQuery: 'salaire');

    expect(filter.isEmpty, isFalse);
    expect(filter.activeCount, 0);
  });
}
