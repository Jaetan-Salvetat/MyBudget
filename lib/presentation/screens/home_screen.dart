import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mybudget/core/routes/app_routes.dart';
import 'package:mybudget/presentation/screens/accounts_screen.dart';
import 'package:mybudget/presentation/screens/dashboard_screen.dart';
import 'package:mybudget/presentation/screens/expenses_screen.dart';
import 'package:mybudget/presentation/screens/loans_screen.dart';
import 'package:mybudget/presentation/screens/revenues_screen.dart';
import 'package:mybudget/presentation/screens/settings_screen.dart';
import 'package:mybudget/presentation/widgets/common/gradient_app_bar.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  
  const HomeScreen({
    this.initialIndex = 0,
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  late RxString _currentTitle;
  
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _currentTitle = _getTitleForIndex(_selectedIndex).obs;
  }
  
  String _getTitleForIndex(int index) {
    switch (index) {
      case 0: return 'MyBudget';
      case 1: return 'Comptes';
      case 2: return 'Dépenses';
      case 3: return 'Revenus';
      case 4: return 'Emprunts';
      case 5: return 'Paramètres';
      default: return 'MyBudget';
    }
  }
  
  static final List<_NavItem> _items = [
    const _NavItem('Accueil', Icons.dashboard_outlined, Icons.dashboard, AppRoutes.dashboard),
    const _NavItem('Comptes', Icons.account_balance_outlined, Icons.account_balance, AppRoutes.accounts),
    const _NavItem('Dépenses', Icons.money_off_outlined, Icons.money_off, AppRoutes.expenses),
    const _NavItem('Revenus', Icons.attach_money_outlined, Icons.attach_money, AppRoutes.revenues),
    const _NavItem('Emprunts', Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, AppRoutes.loans),
    const _NavItem('Paramètres', Icons.settings_outlined, Icons.settings, AppRoutes.settings),
  ];

  final List<Widget> _screens = [
    const DashboardScreen(isNested: true, fabTag: 'dashboard_fab_nested'),
    const AccountsScreen(isNested: true, fabTag: 'accounts_fab_nested'),
    const ExpensesScreen(isNested: true, fabTag: 'expenses_fab_nested'),
    const RevenuesScreen(isNested: true, fabTag: 'revenues_fab_nested'),
    LoansScreen(isNested: true, fabTag: 'loans_fab_nested'),
    const SettingsScreen(isNested: true, fabTag: 'settings_fab_nested'),
  ];

  void _updateTitle() {
    _currentTitle.value = _getTitleForIndex(_selectedIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(() => GradientAppBar(title: _currentTitle.value)),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
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
            selectedIndex: _selectedIndex,
            destinations: [
              for (int i = 0; i < _items.length; i++)
                NavigationDestination(
                  icon: Icon(_items[i].icon),
                  selectedIcon: Icon(_items[i].selectedIcon),
                  label: _items[i].label,
                ),
            ],
            onDestinationSelected: (index) {
              if (_selectedIndex != index) {
                setState(() {
                  _selectedIndex = index;
                  _updateTitle();
                });
              }
            },
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  
  const _NavItem(this.label, this.icon, this.selectedIcon, this.route);
}
