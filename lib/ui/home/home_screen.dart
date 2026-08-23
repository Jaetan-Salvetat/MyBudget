import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/ui/accounts/accounts_screen.dart';
import 'package:mybudget/ui/common/widgets/frosted_background.dart';
import 'package:mybudget/ui/dashboard/dashboard_screen.dart';
import 'package:mybudget/ui/home/home_navigation_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_focus_provider.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';
import 'package:mybudget/ui/settings/screens/update_screen.dart';
import 'package:mybudget/ui/settings/update_provider.dart';
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

  static const List<_NavItem> _items = [
    _NavItem('Accueil', Symbols.dashboard_rounded, Symbols.dashboard_rounded),
    _NavItem(
      'Transactions',
      Symbols.swap_vert_rounded,
      Symbols.swap_vert_rounded,
    ),
    _NavItem(
      'Comptes',
      Symbols.account_balance_rounded,
      Symbols.account_balance_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final quickAddEnabled = ref.watch(quickAddEnabledProvider);
    final selectedTab = ref.watch(
      homeNavigationProvider.select((state) => state.tab),
    );

    const screens = [
      DashboardScreen(isNested: true, fabTag: 'dashboard_fab_nested'),
      TransactionsScreen(),
      AccountsScreen(),
    ];

    return PopScope(
      canPop: selectedTab == HomeTab.dashboard,
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
                    action: quickAddEnabled
                        ? FrostedNavAction(
                            icon: Symbols.auto_awesome_rounded,
                            label: 'Ajout rapide',
                            onPressed: _focusQuickAdd,
                          )
                        : null,
                    destinations: _items
                        .map(
                          (item) => FrostedNavItem(
                            icon: item.icon,
                            selectedIcon: item.selectedIcon,
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

  void _focusQuickAdd() {
    final navigation = ref.read(homeNavigationProvider.notifier);
    if (ref.read(homeNavigationProvider).tab == HomeTab.dashboard) {
      ref.read(quickAddFocusRequestProvider.notifier).request();
      return;
    }

    // The dashboard is still the offstage branch of the stack : asking for
    // focus before the swap lands would leave the keyboard down.
    navigation.selectTab(HomeTab.dashboard);
    Future<void>.delayed(FrostedFadeThroughView.transitionDuration, () {
      if (!mounted) return;
      ref.read(quickAddFocusRequestProvider.notifier).request();
    });
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavItem(this.label, this.icon, this.selectedIcon);
}
