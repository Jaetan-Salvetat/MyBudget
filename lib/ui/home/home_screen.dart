import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/ui/accounts/accounts_screen.dart';
import 'package:mybudget/ui/capture/capture_screen.dart';
import 'package:mybudget/ui/capture/quick_add_landing.dart';
import 'package:mybudget/ui/common/widgets/frosted_background.dart';
import 'package:mybudget/ui/home/home_navigation_provider.dart';
import 'package:mybudget/ui/stats/stats_screen.dart';
import 'package:mybudget/ui/transactions/transactions_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final QuickAddLandingController _landing = QuickAddLandingController();

  @override
  void dispose() {
    _landing.dispose();
    super.dispose();
  }

  static const List<_NavItem> _items = [
    _NavItem('Accueil', Symbols.auto_awesome_rounded),
    _NavItem('Transactions', Symbols.swap_vert_rounded),
    _NavItem('Stats', Symbols.bar_chart_rounded),
    _NavItem('Comptes', Symbols.account_balance_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final selectedTab = ref.watch(
      homeNavigationProvider.select((state) => state.tab),
    );

    const screens = [
      CaptureScreen(),
      TransactionsScreen(),
      StatsScreen(isNested: true),
      AccountsScreen(),
    ];

    return QuickAddLanding(
      notifier: _landing,
      child: PopScope(
        canPop: selectedTab == HomeTab.capture,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (didPop) return;
          ref.read(homeNavigationProvider.notifier).handleBack();
        },
        child: FrostedScaffold(
          extendBodyBehindAppBar: true,
          bottomNavigationBar: FrostedBottomBar(
            folded: keyboardVisible,
            selectedIndex: selectedTab.index,
            onDestinationSelected: (index) => ref
                .read(homeNavigationProvider.notifier)
                .selectTab(HomeTab.values[index]),
            destinations: _items
                .map(
                  (item) => FrostedNavItem(
                    icon: item.icon,
                    selectedIcon: item.icon,
                    label: item.label,
                  ),
                )
                .toList(),
          ),
          body: FrostedBackground(
            child: FrostedFadeThroughView(
              index: selectedTab.index,
              children: screens,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon);
  final String label;
  final IconData icon;
}
