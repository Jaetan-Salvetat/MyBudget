import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/controllers/account_controller.dart';
import '../../../core/controllers/expense_controller.dart';
import '../../../core/controllers/revenue_controller.dart';
import '../../../core/controllers/loan_controller.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/loan_model.dart';

import '../../widgets/common/app_scaffold.dart';
import '../../widgets/accounts/account_bottom_sheet.dart';
import '../loan/loan_details_screen.dart';

class AccountDetailsScreen extends StatefulWidget {
  const AccountDetailsScreen({super.key});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  final AccountController accountController = Get.find<AccountController>();
  final ExpenseController expenseController = Get.find<ExpenseController>();
  final RevenueController revenueController = Get.find<RevenueController>();

  late AccountModel account;

  final formatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    account = Get.arguments as AccountModel;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Détails du compte',
      hideBottomBar: true,
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
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(
          top: 130,
          bottom: 16,
          left: 16,
          right: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAccountHeader(context),
            const SizedBox(height: 24),
            _buildBalanceSection(context),
            const SizedBox(height: 24),
            _buildTransactionsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                        ).colorScheme.primary.withOpacity(0.1),
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

  Widget _buildBalanceSection(BuildContext context) {
    final loanController = Get.find<LoanController>();

    final balance = accountController.getAccountBalance(account.id);
    final totalRevenues = revenueController.revenues
        .where((r) => r.accountId == account.id)
        .fold(0.0, (sum, revenue) => sum + revenue.amount);

    final totalExpenses = expenseController.expenses
        .where((e) => e.accountId == account.id)
        .fold(0.0, (sum, expense) => sum + expense.amount);

    final totalLoanPayments = loanController.getTotalMonthlyPaymentsForAccount(
      account.id,
    );

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
                        ? Colors.green.shade700
                        : Theme.of(context).colorScheme.error)
                    .withOpacity(0.1),
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
                          ).colorScheme.onSurface.withOpacity(0.7),
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
                                  ? Colors.green.shade700
                                  : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    balance >= 0 ? Icons.trending_up : Icons.trending_down,
                    color:
                        balance >= 0
                            ? Colors.green.shade700
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
        color: color.withOpacity(0.1),
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
                  color: color.withOpacity(0.8),
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

  Widget _buildTransactionsSection(BuildContext context) {
    final expenses =
        expenseController.expenses
            .where((e) => e.accountId == account.id)
            .toList();
    expenses.sort((a, b) => b.date.compareTo(a.date));

    final revenues =
        revenueController.revenues
            .where((r) => r.accountId == account.id)
            .toList();
    revenues.sort((a, b) => b.date.compareTo(a.date));

    final loanController = Get.find<LoanController>();
    final loans =
        loanController
            .getLoansForAccount(account.id)
            .where((loan) => loan.getAutomaticStatus() != LoanStatus.completed)
            .toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transactions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
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
                        ).colorScheme.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune transaction pour ce compte',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (revenues.isNotEmpty)
                    ..._buildTransactionsList(
                      context,
                      'Revenus',
                      revenues.length,
                      Theme.of(context).colorScheme.primary,
                      revenues
                          .map(
                            (revenue) => {
                              'name': revenue.name,
                              'amount': revenue.amount,
                              'date': revenue.date,
                              'type': 'revenue',
                              'icon': Icons.arrow_upward,
                              'color': Theme.of(context).colorScheme.primary,
                            },
                          )
                          .toList(),
                    ),

                  if (expenses.isNotEmpty)
                    ..._buildTransactionsList(
                      context,
                      'Dépenses',
                      expenses.length,
                      Theme.of(context).colorScheme.error,
                      expenses
                          .map(
                            (expense) => {
                              'name': expense.name,
                              'amount': expense.amount,
                              'date': expense.date,
                              'type': 'expense',
                              'icon': Icons.arrow_downward,
                              'color': Theme.of(context).colorScheme.error,
                            },
                          )
                          .toList(),
                    ),

                  if (loans.isNotEmpty)
                    ..._buildTransactionsList(
                      context,
                      'Mensualités',
                      loans.length,
                      Theme.of(context).colorScheme.secondary,
                      loans
                          .map(
                            (loan) => {
                              'name': loan.name,
                              'amount': loan.monthlyPayment,
                              'date': loan.startDate,
                              'type': 'loan',
                              'icon': Icons.account_balance,
                              'color': Theme.of(context).colorScheme.secondary,
                            },
                          )
                          .toList(),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTransactionsList(
    BuildContext context,
    String title,
    int count,
    Color badgeColor,
    List<Map<String, dynamic>> items,
  ) {
    return [
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 8),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
            ),
            const Spacer(),
            if (items.length > 5)
              TextButton(onPressed: () {}, child: const Text('Voir plus')),
          ],
        ),
      ),
      ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shrinkWrap: true,
        itemCount: items.length > 5 ? 5 : items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color:
                              item['type'] == 'expense'
                                  ? Theme.of(context).colorScheme.errorContainer
                                  : item['type'] == 'loan'
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer
                                  : Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item['icon'], color: item['color']),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd/MM/yyyy').format(item['date']),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatter.format(item['amount']),
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color:
                              item['type'] == 'expense'
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (item['type'] == 'loan')
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          final loan = Get.find<LoanController>().loans
                              .firstWhere(
                                (l) =>
                                    l.name == item['name'] &&
                                    l.amount == item['amount'],
                              );
                          Get.to(() => LoanDetailsScreen(), arguments: loan);
                        },
                        child: const Text('Voir détails'),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ];
  }

  void _showEditAccountBottomSheet(BuildContext context) {
    AccountBottomSheet.show(
      context: context,
      account: account,
      onSubmit: (name, bank) {
        final updatedAccount = account.copyWith(name: name, bank: bank);
        accountController.updateAccount(updatedAccount);
        setState(() {
          account = updatedAccount;
        });
      },
      onCancel: () => {},
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
                  accountController.deleteAccount(account.id);
                  Navigator.of(context).pop();
                  Get.back();
                },
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
  }
}
