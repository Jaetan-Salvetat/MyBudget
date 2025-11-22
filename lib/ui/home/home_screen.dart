import 'package:flutter/material.dart';
import 'package:mybudget/ui/dashboard/dashboard_screen.dart';
import 'package:mybudget/ui/accounts/accounts_screen.dart';
import 'package:mybudget/ui/expenses/expenses_screen.dart';
import 'package:mybudget/ui/revenues/revenues_screen.dart';
import 'package:mybudget/ui/loans/loans_screen.dart';
import 'package:mybudget/ui/settings/settings_screen.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:provider/provider.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/accounts/accounts_viewmodel.dart';
import 'package:mybudget/ui/expenses/expenses_viewmodel.dart';
import 'package:mybudget/ui/revenues/revenues_viewmodel.dart';
import 'package:mybudget/ui/loans/loans_viewmodel.dart';
import 'package:mybudget/ui/settings/category_viewmodel.dart';
import 'package:mybudget/ui/accounts/widgets/account_bottom_sheet.dart';
import 'package:mybudget/ui/expenses/widgets/expense_bottom_sheet.dart';
import 'package:mybudget/ui/revenues/widgets/revenue_bottom_sheet.dart';
import 'package:mybudget/ui/loans/widgets/loan_bottom_sheet.dart';

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
    const AccountsScreen(),
    const ExpensesScreen(),
    const RevenuesScreen(),
    const LoansScreen(),
    const SettingsScreen(),
  ];

  void _updateTitle() {
    setState(() {
      _currentTitle = _getTitleForIndex(_selectedIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FrostedScaffold(
      appBar: FrostedAppBar(title: _currentTitle),
      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
      child: IndexedStack(index: _selectedIndex, children: _screens),
    );
  }

  Widget? _buildFab(BuildContext context) {
    switch (_selectedIndex) {
      case 1: // Comptes
        return FrostedFloatingActionButton(
          onPressed: () => _showAddAccountDialog(context),
          child: const Icon(Icons.add),
        );
      case 2: // Dépenses
        return FrostedFloatingActionButton(
          onPressed: () => _showAddExpenseBottomSheet(context),
          child: const Icon(Icons.add),
        );
      case 3: // Revenus
        return FrostedFloatingActionButton(
          onPressed: () => _showAddRevenueBottomSheet(context),
          child: const Icon(Icons.add),
        );
      case 4: // Emprunts
        return FrostedFloatingActionButton(
          onPressed: () => _showAddLoanBottomSheet(context),
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }

  void _showAddAccountDialog(BuildContext context) {
    final accountViewModel = Provider.of<AccountViewModel>(
      context,
      listen: false,
    );

    AccountBottomSheet.show(
      context: context,
      onSubmit: (name, bank) {
        if (name.isEmpty || bank.isEmpty) return;

        final account = AccountModel.create(name: name, bank: bank);
        accountViewModel.addAccount(account);
      },
      onCancel: () {},
    );
  }

  void _showAddExpenseBottomSheet(BuildContext context) {
    final accountViewModel = Provider.of<AccountViewModel>(
      context,
      listen: false,
    );
    final expenseViewModel = Provider.of<ExpenseViewModel>(
      context,
      listen: false,
    );
    final categoryViewModel = Provider.of<CategoryViewModel>(
      context,
      listen: false,
    );

    if (accountViewModel.accounts.isEmpty) {
      _showNoAccountDialog(context, 'une dépense');
      return;
    }

    ExpenseBottomSheet.show(
      context: context,
      accounts: accountViewModel.accounts,
      categories: categoryViewModel.categories,
      onSubmit: (expense) async {
        try {
          await expenseViewModel.addExpense(expense);
        } catch (e) {
          if (context.mounted) {
            FrostedSnackbar.show(
              context,
              message: 'Erreur lors de l\'ajout: $e',
            );
          }
        }
      },
      onCancel: () {},
    );
  }

  void _showAddRevenueBottomSheet(BuildContext context) {
    final accountViewModel = Provider.of<AccountViewModel>(
      context,
      listen: false,
    );
    final revenueViewModel = Provider.of<RevenueViewModel>(
      context,
      listen: false,
    );

    if (accountViewModel.accounts.isEmpty) {
      _showNoAccountDialog(context, 'un revenu');
      return;
    }

    RevenueBottomSheet.show(
      context: context,
      accounts: accountViewModel.accounts,
      onSubmit: (revenue) {
        revenueViewModel.addRevenue(revenue);
      },
      onCancel: () {},
    );
  }

  void _showAddLoanBottomSheet(BuildContext context) {
    final accountViewModel = Provider.of<AccountViewModel>(
      context,
      listen: false,
    );
    final loanViewModel = Provider.of<LoanViewModel>(context, listen: false);

    if (accountViewModel.accounts.isEmpty) {
      _showNoAccountDialog(context, 'un emprunt');
      return;
    }

    LoanBottomSheet.show(
      context: context,
      accounts: accountViewModel.accounts,
      onSubmit: (loan) {
        loanViewModel.addLoan(loan);
      },
      onCancel: () {},
    );
  }

  void _showNoAccountDialog(BuildContext context, String action) {
    FrostedDialog.show(
      context: context,
      barrierDismissible: false,
      title: const Text('Aucun compte disponible'),
      content: Text(
        'Vous devez d\'abord créer un compte avant d\'ajouter $action.',
      ),
      actions: [
        FrostedTextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavItem(this.label, this.icon, this.selectedIcon);
}
