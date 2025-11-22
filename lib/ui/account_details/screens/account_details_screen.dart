import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/accounts/accounts_viewmodel.dart';
import 'package:mybudget/ui/expenses/expenses_viewmodel.dart';
import 'package:mybudget/ui/revenues/revenues_viewmodel.dart';
import 'package:mybudget/ui/loans/loans_viewmodel.dart';
import 'package:mybudget/ui/accounts/widgets/account_bottom_sheet.dart';
 
 
 
 
 
import 'package:mybudget/ui/account_details/widgets/account_expense_list.dart';
import 'package:mybudget/ui/account_details/widgets/account_revenue_list.dart';
import 'package:mybudget/ui/account_details/widgets/account_loan_list.dart';
import 'package:mybudget/ui/account_details/widgets/transaction_tabs.dart';

class AccountDetailsScreen extends StatefulWidget {
  final AccountModel account;

  const AccountDetailsScreen({required this.account, super.key});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AccountModel account;
  TabController? _tabController;

  final formatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 2,
  );

  final List<String> _tabLabels = ['Dépenses', 'Revenus', 'Mensualités'];
   

  @override
  void initState() {
    super.initState();
    account = widget.account;
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _tabController!.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (_tabController!.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabSelection);
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> tabColors = [
      Theme.of(context).colorScheme.error,  
      Theme.of(context).colorScheme.primary,  
      Theme.of(context).colorScheme.secondary,  
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du compte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditAccountBottomSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: Consumer4<
        AccountViewModel,
        ExpenseViewModel,
        RevenueViewModel,
        LoanViewModel
      >(
        builder: (context, accountVM, expenseVM, revenueVM, loanVM, child) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAccountHeader(context, account),
                const SizedBox(height: 24),
                _buildBalanceSection(
                  context,
                  accountVM,
                  expenseVM,
                  revenueVM,
                  loanVM,
                ),
                const SizedBox(height: 24),
                _buildTransactionsSection(
                  context,
                  expenseVM,
                  revenueVM,
                  loanVM,
                  tabColors,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccountHeader(BuildContext context, AccountModel account) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        account.bank,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSection(
    BuildContext context,
    AccountViewModel accountVM,
    ExpenseViewModel expenseVM,
    RevenueViewModel revenueVM,
    LoanViewModel loanVM,
  ) {
    final balance = accountVM.getAccountBalance(account.id);

    final totalRevenues = revenueVM.revenues
        .where((r) => r.accountId == account.id)
        .fold(0.0, (sum, revenue) => sum + revenue.amount);

    final totalExpenses = expenseVM.expenses
        .where((e) => e.accountId == account.id)
        .fold(0.0, (sum, expense) => sum + expense.amount);

    final totalLoanPayments = loanVM.loans
        .where((l) => l.accountId == account.id && !l.isCompleted())
        .fold(0.0, (sum, loan) => sum + loan.monthlyPayment);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Solde et transactions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (balance >= 0
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Solde total',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatter.format(balance),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color:
                              balance >= 0
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    balance >= 0 ? Icons.trending_up : Icons.trending_down,
                    color:
                        balance >= 0
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error,
                    size: 32,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Dépenses',
                    totalExpenses + totalLoanPayments,
                    Icons.arrow_downward,
                    Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Revenus',
                    totalRevenues,
                    Icons.arrow_upward,
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatter.format(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection(
    BuildContext context,
    ExpenseViewModel expenseVM,
    RevenueViewModel revenueVM,
    LoanViewModel loanVM,
    List<Color> tabColors,
  ) {
    final expenses = expenseVM.getExpensesForAccount(account.id);
    final revenues = revenueVM.getRevenuesForAccount(account.id);
    final loans = loanVM.getActiveLoansForAccount(account.id);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (expenses.isEmpty && revenues.isEmpty && loans.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 48,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune transaction pour ce compte',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  if (_tabController != null)
                    TransactionTabs(
                      tabController: _tabController!,
                      tabLabels: _tabLabels,
                      tabColors: tabColors,
                    ),
                  const SizedBox(height: 16),
                  _tabController == null
                      ? const Center(child: CircularProgressIndicator())
                      : Builder(
                        builder: (context) {
                          final int currentIndex = _tabController!.index;

                          switch (currentIndex) {
                            case 0:  
                              return AccountExpenseList(
                                expenses: expenses,
                                formatter: formatter,
                              );
                            case 1:  
                              return AccountRevenueList(
                                revenues: revenues,
                                formatter: formatter,
                              );
                            case 2:  
                              return AccountLoanList(
                                loans: loans,
                                formatter: formatter,
                              );
                            default:
                              return const SizedBox.shrink();
                          }
                        },
                      ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showEditAccountBottomSheet(BuildContext context) {
    final accountVM = Provider.of<AccountViewModel>(context, listen: false);

    AccountBottomSheet.show(
      context: context,
      account: account,
      onSubmit: (name, bank) {
        final updatedAccount = account.copyWith(name: name, bank: bank);
        accountVM.updateAccount(updatedAccount);
        setState(() {
          account = updatedAccount;
        });
      },
      onCancel: () {},
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: Text(
              'Voulez-vous vraiment supprimer le compte ${account.name} ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () {
                  final accountVM = Provider.of<AccountViewModel>(
                    context,
                    listen: false,
                  );
                  accountVM.deleteAccount(account.id);
                  Navigator.of(context).pop();  
                  Navigator.of(context).pop();  
                },
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
  }
}
