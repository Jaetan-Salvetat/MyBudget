import 'package:flutter/material.dart';
import 'package:mybudget/ui/dashboard/dashboard_screen.dart';
import 'package:mybudget/ui/accounts/accounts_screen.dart';
import 'package:mybudget/ui/expenses/expenses_screen.dart';
import 'package:mybudget/ui/revenues/revenues_screen.dart';
import 'package:mybudget/ui/loans/loans_screen.dart';
import 'package:mybudget/ui/settings/settings_screen.dart';
import 'package:frosted_ui/frosted_ui.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({this.initialIndex = 0, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  late String _currentTitle;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _currentTitle = _getTitleForIndex(_selectedIndex);
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'MyBudget';
      case 1:
        return 'Comptes';
      case 2:
        return 'Dépenses';
      case 3:
        return 'Revenus';
      case 4:
        return 'Emprunts';
      case 5:
        return 'Paramètres';
      default:
        return 'MyBudget';
    }
  }

  static final List<_NavItem> _items = [
    const _NavItem('Accueil', Icons.dashboard_outlined, Icons.dashboard),
    const _NavItem(
      'Comptes',
      Icons.account_balance_outlined,
      Icons.account_balance,
    ),
    const _NavItem('Dépenses', Icons.money_off_outlined, Icons.money_off),
    const _NavItem('Revenus', Icons.attach_money_outlined, Icons.attach_money),
    const _NavItem(
      'Emprunts',
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet,
    ),
    const _NavItem('Paramètres', Icons.settings_outlined, Icons.settings),
  ];

  final List<Widget> _screens = [
    const DashboardScreen(isNested: true, fabTag: 'dashboard_fab_nested'),
    const AccountsScreen(isNested: true, fabTag: 'accounts_fab_nested'),
    const ExpensesScreen(isNested: true, fabTag: 'expenses_fab_nested'),
    const RevenuesScreen(isNested: true, fabTag: 'revenues_fab_nested'),
    const LoansScreen(isNested: true, fabTag: 'loans_fab_nested'),
    const SettingsScreen(isNested: true, fabTag: 'settings_fab_nested'),
  ];

  void _updateTitle() {
    setState(() {
      _currentTitle = _getTitleForIndex(_selectedIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FrostedScaffold(
      extendBodyBehindAppBar: true,
      appBar: FrostedAppBar(title: _currentTitle),
      child: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: FrostedBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (_selectedIndex != index) {
            setState(() {
              _selectedIndex = index;
              _updateTitle();
            });
          }
        },
        items:
            _items
                .map(
                  (item) => BottomNavigationBarItem(
                    icon: Icon(item.icon),
                    activeIcon: Icon(item.selectedIcon),
                    label: item.label,
                  ),
                )
                .toList(),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavItem(this.label, this.icon, this.selectedIcon);
}
