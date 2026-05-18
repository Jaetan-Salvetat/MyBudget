import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mybudget/ui/dashboard/dashboard_screen.dart';
import 'package:mybudget/ui/accounts/accounts_screen.dart';
import 'package:mybudget/ui/expenses/expenses_screen.dart';
import 'package:mybudget/ui/revenues/revenues_screen.dart';
import 'package:mybudget/ui/loans/loans_screen.dart';
import 'package:mybudget/ui/settings/settings_screen.dart';
import 'package:mybudget/ui/scan/scan_screen.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/ui/settings/category_provider.dart';
import 'package:mybudget/ui/settings/update_provider.dart';
import 'package:mybudget/ui/settings/screens/update_screen.dart';
import 'package:mybudget/ui/accounts/widgets/account_bottom_sheet.dart';
import 'package:mybudget/ui/expenses/widgets/expense_bottom_sheet.dart';
import 'package:mybudget/ui/revenues/widgets/revenue_bottom_sheet.dart';
import 'package:mybudget/ui/loans/widgets/loan_creation_bottom_sheet.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const HomeScreen({this.initialIndex = 0, super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _selectedIndex;
  late String _currentTitle;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _currentTitle = _getTitleForIndex(_selectedIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(updateProvider.notifier).checkForUpdates(silent: true);
      ref.listenManual(updateProvider, (previous, next) {
        if (previous?.availableUpdate == null &&
            next.availableUpdate != null &&
            context.mounted) {
          FrostedSnackbar.show(
            context,
            message: 'Mise à jour v${next.availableUpdate!.version} disponible',
            action: SnackBarAction(
              label: 'Voir',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpdateScreen()),
              ),
            ),
          );
        }
      });
    });
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
  ];

  final List<Widget> _screens = [
    const DashboardScreen(isNested: true, fabTag: 'dashboard_fab_nested'),
    const AccountsScreen(),
    const ExpensesScreen(),
    const RevenuesScreen(),
    const LoansScreen(),
  ];

  void _updateTitle() {
    setState(() {
      _currentTitle = _getTitleForIndex(_selectedIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FrostedScaffold(
      animateFloatingActionButtonTransitions: false,
      appBar: FrostedAppBar(
        title: _currentTitle,
        actions: [
          FrostedIconButton(
            icon: Icons.settings,
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QuickAddSection(
            onNoAccount: () => _showNoAccountDialog(context, 'une dépense'),
          ),
          FrostedBottomNavigationBar(
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
        ],
      ),
      child: IndexedStack(index: _selectedIndex, children: _screens),
    );
  }

  Widget? _buildFab(BuildContext context) {
    switch (_selectedIndex) {
      case 1:
        return FrostedFloatingActionButton(
          onPressed: () => _showAddAccountDialog(context),
          child: const Icon(Icons.add),
        );
      case 2:
        return FrostedExpandableFab(
          children: [
            FrostedExpandableFabChild(
              icon: const Icon(Icons.document_scanner),
              label: 'Scanner',
              onPressed: () => _showImageSourceChoice(context),
            ),
            FrostedExpandableFabChild(
              icon: const Icon(Icons.edit),
              label: 'Manuel',
              onPressed: () => _showAddExpenseBottomSheet(context),
            ),
          ],
        );
      case 3:
        return FrostedFloatingActionButton(
          onPressed: () => _showAddRevenueBottomSheet(context),
          child: const Icon(Icons.add),
        );
      case 4:
        return FrostedFloatingActionButton(
          onPressed: () => _showAddLoanBottomSheet(context),
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }

  void _showAddAccountDialog(BuildContext context) {
    AccountBottomSheet.show(
      context: context,
      onSubmit: (name, bank) async {
        if (name.isEmpty || bank.isEmpty) return;

        try {
          final account = AccountModel.create(name: name, bank: bank);
          await ref.read(accountProvider.notifier).addAccount(account);
        } catch (e) {
          if (context.mounted) {
            FrostedSnackbar.show(context, message: 'Erreur lors de l\'ajout: \$e');
          }
        }
      },
      onCancel: () {},
    );
  }

  void _showAddExpenseBottomSheet(BuildContext context) {
    final accounts = ref.read(accountProvider).value ?? [];

    if (accounts.isEmpty) {
      _showNoAccountDialog(context, 'une dépense');
      return;
    }

    ExpenseBottomSheet.show(
      context: context,
      accounts: accounts,
      categories: ref.read(categoryProvider).value ?? [],
      closedExpenses: ref.read(expenseProvider.notifier).getClosedExpenses(),
      onSubmit: (expense) async {
        try {
          await ref.read(expenseProvider.notifier).addExpense(expense);
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
    final accounts = ref.read(accountProvider).value ?? [];

    if (accounts.isEmpty) {
      _showNoAccountDialog(context, 'un revenu');
      return;
    }

    RevenueBottomSheet.show(
      context: context,
      accounts: accounts,
      closedRevenues: ref.read(revenueProvider.notifier).getClosedRevenues(),
      onSubmit: (revenue) async {
        try {
          await ref.read(revenueProvider.notifier).addRevenue(revenue);
        } catch (e) {
          if (context.mounted) {
            FrostedSnackbar.show(context, message: 'Erreur lors de l\'ajout: \$e');
          }
        }
      },
      onCancel: () {},
    );
  }

  void _showAddLoanBottomSheet(BuildContext context) {
    final accounts = ref.read(accountProvider).value ?? [];

    if (accounts.isEmpty) {
      _showNoAccountDialog(context, 'un emprunt');
      return;
    }

    LoanCreationBottomSheet.show(
      context: context,
      accounts: accounts,
      onSubmit: (loan) async {
        try {
          await ref.read(loanProvider.notifier).addLoan(loan);
        } catch (e) {
          if (context.mounted) {
            FrostedSnackbar.show(context, message: 'Erreur lors de l\'ajout: \$e');
          }
        }
      },
      onCancel: () {},
    );
  }

  void _showImageSourceChoice(BuildContext context) {
    final accounts = ref.read(accountProvider).value ?? [];

    if (accounts.isEmpty) {
      _showNoAccountDialog(context, 'une dépense');
      return;
    }

    FrostedBottomSheet.show(
      context: context,
      title: 'Scanner un ticket',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FrostedListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Prendre une photo'),
            onTap: () {
              Navigator.pop(context);
              _pickImageAndScan(context, ImageSource.camera);
            },
          ),
          FrostedListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choisir depuis la galerie'),
            onTap: () {
              Navigator.pop(context);
              _pickImageAndScan(context, ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageAndScan(
    BuildContext context,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      imageQuality: 85,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanScreen(imageBytes: bytes),
        ),
      );
    }
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
