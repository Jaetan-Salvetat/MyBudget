import 'package:flutter/material.dart';
import 'package:mybudget/presentation/widgets/common/gradient_app_bar.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  final String title;
  final bool useNestedAppBar;
  final FloatingActionButton? floatingActionButton;
  final List<Widget>? actions;
  final bool hideBottomBar;
  
  const AppScaffold({
    required this.child,
    this.title = 'MyBudget',
    this.useNestedAppBar = false,
    this.floatingActionButton,
    this.actions,
    this.hideBottomBar = false,
    super.key,
  });

  static final List<_NavItem> _items = [
    const _NavItem('Accueil', Icons.dashboard_outlined, '/home'),
    const _NavItem('Comptes', Icons.account_balance_outlined, '/accounts'),
    const _NavItem('Dépenses', Icons.money_off_outlined, '/expenses'),
    const _NavItem('Revenus', Icons.attach_money_outlined, '/revenues'),
    const _NavItem('Emprunts', Icons.account_balance_wallet_outlined, '/loans'),
    const _NavItem('Paramètres', Icons.settings_outlined, '/settings'),
  ];

  int _locationToIndex(String location) {
    for (int i = 0; i < _items.length; i++) {
      if (location == _items[i].route) {
        return i;
      }
    }
    return 0;
  }

  IconData _getSelectedIcon(IconData icon) {
    if (icon == Icons.dashboard) return Icons.dashboard;
    if (icon == Icons.dashboard_outlined) return Icons.dashboard;
    if (icon == Icons.account_balance) return Icons.account_balance;
    if (icon == Icons.account_balance_outlined) return Icons.account_balance;
    if (icon == Icons.money_off) return Icons.money_off;
    if (icon == Icons.money_off_outlined) return Icons.money_off;
    if (icon == Icons.attach_money) return Icons.attach_money;
    if (icon == Icons.attach_money_outlined) return Icons.attach_money;
    if (icon == Icons.account_balance_wallet) return Icons.account_balance_wallet;
    if (icon == Icons.account_balance_wallet_outlined) return Icons.account_balance_wallet;
    if (icon == Icons.settings) return Icons.settings;
    if (icon == Icons.settings_outlined) return Icons.settings;

    return icon;
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/home';
    final selectedIndex = _locationToIndex(currentRoute);

    return Scaffold(
      appBar: useNestedAppBar ? null : _buildGradientAppBar(context),
      extendBodyBehindAppBar: !useNestedAppBar,
      body: child,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: hideBottomBar ? null : Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          child: NavigationBar(
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            selectedIndex: selectedIndex,
            destinations: [
              for (int i = 0; i < _items.length; i++)
                NavigationDestination(
                  icon: Icon(_items[i].icon),
                  selectedIcon: Icon(_getSelectedIcon(_items[i].icon)),
                  label: _items[i].label,
                ),
            ],
            onDestinationSelected: (index) {
              final route = _items[index].route;
              if (currentRoute != route) {
                Navigator.pushReplacementNamed(context, route);
              }
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildGradientAppBar(BuildContext context) {
    return GradientAppBar(title: title, actions: actions);
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  const _NavItem(this.label, this.icon, this.route);
}
