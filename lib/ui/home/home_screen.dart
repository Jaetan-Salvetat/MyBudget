import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/ui/accounts/accounts_screen.dart';
import 'package:mybudget/ui/capture/capture_screen.dart';
import 'package:mybudget/ui/common/widgets/frosted_background.dart';
import 'package:mybudget/ui/home/home_navigation_provider.dart';
import 'package:mybudget/ui/settings/screens/update_screen.dart';
import 'package:mybudget/ui/settings/update_provider.dart';
import 'package:mybudget/ui/stats/stats_screen.dart';
import 'package:mybudget/ui/transactions/transactions_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(updateProvider.notifier).checkForUpdates(silent: true);
      ref.listenManual(updateProvider, (previous, next) {
        if (previous?.availableUpdate == null &&
            next.availableUpdate != null &&
            context.mounted) {
          FrostedSnackbar.show(
            context,
            message: 'Mise à jour v${next.availableUpdate!.version} disponible',
            actionLabel: 'Voir',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UpdateScreen()),
            ),
          );
        }
      });
    });
  }

  /// Four destinations, no action button : the start destination *is* the
  /// quick add, so a shortcut back to it would point at itself.
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

    return PopScope(
      canPop: selectedTab == HomeTab.capture,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        ref.read(homeNavigationProvider.notifier).handleBack();
      },
      child: FrostedScaffold(
        extendBodyBehindAppBar: true,
        bottomNavigationBar: keyboardVisible
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: FrostedSpacing.sp3),
                  child: FrostedNavPill(
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
                ),
              ),
        body: FrostedBackground(
          child: FrostedFadeThroughView(
            index: selectedTab.index,
            children: screens,
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;

  const _NavItem(this.label, this.icon);
}
