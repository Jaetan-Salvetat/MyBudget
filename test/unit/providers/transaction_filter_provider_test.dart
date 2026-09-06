import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/transaction_filter_provider.dart';

void main() {
  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('TransactionFilterNotifier', () {
    test('starts empty', () {
      final container = makeContainer();

      expect(container.read(expensesFilterProvider).isEmpty, isTrue);
    });

    test('showOnlyGroup replaces the selected groups', () {
      final container = makeContainer();
      final notifier = container.read(expensesFilterProvider.notifier);

      notifier.toggleGroup('logement');
      notifier.showOnlyGroup('alimentation');

      expect(container.read(expensesFilterProvider).groupKeys, [
        'alimentation',
      ]);
    });

    test('showOnlyGroup clears the other criteria', () {
      final container = makeContainer();
      final notifier = container.read(expensesFilterProvider.notifier);

      notifier.update(
        (filter) => filter.copyWith(
          minAmount: 10,
          types: [Frequency.monthly],
          searchQuery: 'loyer',
        ),
      );
      notifier.showOnlyGroup('alimentation');

      final filter = container.read(expensesFilterProvider);
      expect(filter.groupKeys, ['alimentation']);
      expect(filter.minAmount, isNull);
      expect(filter.types, isEmpty);
      expect(filter.searchQuery, isNull);
    });

    test('toggleGroup adds then removes a group', () {
      final container = makeContainer();
      final notifier = container.read(expensesFilterProvider.notifier);

      notifier.toggleGroup('logement');
      expect(container.read(expensesFilterProvider).groupKeys, ['logement']);

      notifier.toggleGroup('logement');
      expect(container.read(expensesFilterProvider).groupKeys, isEmpty);
    });

    test('clearGroups drops every group but keeps the search query', () {
      final container = makeContainer();
      final notifier = container.read(expensesFilterProvider.notifier);

      notifier.update((filter) => filter.copyWith(searchQuery: 'loyer'));
      notifier.toggleGroup('logement');
      notifier.clearGroups();

      final filter = container.read(expensesFilterProvider);
      expect(filter.groupKeys, isEmpty);
      expect(filter.searchQuery, 'loyer');
    });

    test('reset keeps the search query only', () {
      final container = makeContainer();
      final notifier = container.read(expensesFilterProvider.notifier);

      notifier.update(
        (filter) => filter.copyWith(searchQuery: 'loyer', minAmount: 10),
      );
      notifier.reset();

      final filter = container.read(expensesFilterProvider);
      expect(filter.searchQuery, 'loyer');
      expect(filter.minAmount, isNull);
    });

    test('clearAll drops the search query too', () {
      final container = makeContainer();
      final notifier = container.read(expensesFilterProvider.notifier);

      notifier.update(
        (filter) => filter.copyWith(searchQuery: 'loyer', minAmount: 10),
      );
      notifier.clearAll();

      expect(container.read(expensesFilterProvider).isEmpty, isTrue);
    });

    test('revenues and expenses hold independent filters', () {
      final container = makeContainer();

      container.read(expensesFilterProvider.notifier).toggleGroup('logement');

      expect(container.read(revenuesFilterProvider).groupKeys, isEmpty);
      expect(container.read(expensesFilterProvider).groupKeys, ['logement']);
    });
  });
}
