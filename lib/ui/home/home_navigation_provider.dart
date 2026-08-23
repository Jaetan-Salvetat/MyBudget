import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HomeTab { dashboard, transactions, accounts }

enum TransactionsTab { expenses, revenues, loans }

class HomeNavigationState {
  final HomeTab tab;
  final TransactionsTab transactionsTab;

  const HomeNavigationState({
    this.tab = HomeTab.dashboard,
    this.transactionsTab = TransactionsTab.expenses,
  });

  HomeNavigationState copyWith({
    HomeTab? tab,
    TransactionsTab? transactionsTab,
  }) {
    return HomeNavigationState(
      tab: tab ?? this.tab,
      transactionsTab: transactionsTab ?? this.transactionsTab,
    );
  }
}

class HomeNavigationNotifier extends Notifier<HomeNavigationState> {
  @override
  HomeNavigationState build() => const HomeNavigationState();

  void selectTab(HomeTab tab) {
    if (state.tab == tab) return;
    state = state.copyWith(tab: tab);
  }

  /// Android hands a top-level destination back to the start destination
  /// before letting the back gesture leave the app. Returns whether the pop
  /// was consumed here.
  bool handleBack() {
    if (state.tab == HomeTab.dashboard) return false;
    selectTab(HomeTab.dashboard);
    return true;
  }

  void selectTransactionsTab(TransactionsTab transactionsTab) {
    if (state.transactionsTab == transactionsTab) return;
    state = state.copyWith(transactionsTab: transactionsTab);
  }

  void openTransactions(TransactionsTab transactionsTab) {
    state = HomeNavigationState(
      tab: HomeTab.transactions,
      transactionsTab: transactionsTab,
    );
  }
}

final homeNavigationProvider =
    NotifierProvider<HomeNavigationNotifier, HomeNavigationState>(
      HomeNavigationNotifier.new,
    );
