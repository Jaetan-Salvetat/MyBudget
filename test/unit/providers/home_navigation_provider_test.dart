import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/ui/home/home_navigation_provider.dart';

void main() {
  group('HomeNavigationNotifier', () {
    ProviderContainer makeContainer() {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      return container;
    }

    test('starts on the dashboard with the expenses sub-tab', () {
      final container = makeContainer();

      final state = container.read(homeNavigationProvider);

      expect(state.tab, HomeTab.dashboard);
      expect(state.transactionsTab, TransactionsTab.expenses);
    });

    test('selectTab keeps the current transactions sub-tab', () {
      final container = makeContainer();
      final notifier = container.read(homeNavigationProvider.notifier);

      notifier.selectTransactionsTab(TransactionsTab.loans);
      notifier.selectTab(HomeTab.accounts);

      expect(container.read(homeNavigationProvider).tab, HomeTab.accounts);
      expect(
        container.read(homeNavigationProvider).transactionsTab,
        TransactionsTab.loans,
      );
    });

    test('openTransactions selects the transactions tab and its sub-tab', () {
      final container = makeContainer();

      container
          .read(homeNavigationProvider.notifier)
          .openTransactions(TransactionsTab.loans);

      final state = container.read(homeNavigationProvider);
      expect(state.tab, HomeTab.transactions);
      expect(state.transactionsTab, TransactionsTab.loans);
    });
  });
}
