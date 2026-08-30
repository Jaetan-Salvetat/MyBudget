import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HomeTab { capture, transactions, stats, accounts }

enum TransactionsTab { expenses, revenues, loans }

class HomeNavigationState {
  final HomeTab tab;
  final TransactionsTab transactionsTab;

  const HomeNavigationState({
    this.tab = HomeTab.capture,
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

  bool handleBack() {
    if (state.tab == HomeTab.capture) return false;
    selectTab(HomeTab.capture);
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

  void openStats() => selectTab(HomeTab.stats);
}

final homeNavigationProvider =
    NotifierProvider<HomeNavigationNotifier, HomeNavigationState>(
      HomeNavigationNotifier.new,
    );
