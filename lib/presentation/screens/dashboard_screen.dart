import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/controllers/account_controller.dart';
import 'package:mybudget/core/controllers/expense_controller.dart';
import 'package:mybudget/core/controllers/revenue_controller.dart';
import 'package:mybudget/core/controllers/loan_controller.dart';


import 'package:mybudget/presentation/widgets/common/filter_chip.dart';
import 'package:mybudget/presentation/widgets/dashboard/balance_card.dart';
import 'package:mybudget/presentation/widgets/dashboard/account_card.dart';
import 'package:mybudget/presentation/widgets/dashboard/transaction_item.dart';
import 'package:mybudget/presentation/widgets/dashboard/section_header.dart';
import 'package:mybudget/presentation/widgets/dashboard/empty_state.dart';
import 'package:mybudget/presentation/widgets/common/app_scaffold.dart';
import 'package:mybudget/presentation/widgets/dashboard/active_loans_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accountController = Get.find<AccountController>();
    final expenseController = Get.find<ExpenseController>();
    final revenueController = Get.find<RevenueController>();
    
    final accounts = accountController.accounts;
    final expenses = expenseController.expenses;
    final revenues = revenueController.revenues;

    return AppScaffold(
      title: 'MyBudget',
      child: Scaffold(
        body: Obx(() => 
          accounts.isEmpty && expenses.isEmpty && revenues.isEmpty
            ? EmptyDashboardState(
                onSetupPressed: () => Get.toNamed('/accounts'),
              )
            : _buildDashboard(context),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final accountController = Get.find<AccountController>();
    final expenseController = Get.find<ExpenseController>();
    final revenueController = Get.find<RevenueController>();
    final loanController = Get.find<LoanController>();
    
    final accounts = accountController.accounts;
    
    final netCashFlow = accountController.getNetCashFlow();
    final savingsRate = accountController.getSavingsRate();
    final totalLoanAmount = loanController.getTotalRemainingAmount();
    final monthlyExpenses = expenseController.getMonthlyExpenses();
    final monthlyRevenues = revenueController.getMonthlyRevenues();
    final totalMonthlyLoanPayments = loanController.getTotalMonthlyPayments();
    final totalExpenses = monthlyExpenses + totalMonthlyLoanPayments;

    final NumberFormat formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
    );
    
    final recentExpenses = expenseController.getRecentExpenses(3);
    final recentRevenues = revenueController.getRecentRevenues(3);
    final activeLoans = loanController.getActiveLoans();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 100),
          
          // Carte de solde total avec toutes les informations financières
          BalanceCard(
            balance: netCashFlow,
            netFlow: totalLoanAmount,
            savingsRate: savingsRate,
            formatter: formatter,
            expenses: totalExpenses,
            revenues: monthlyRevenues,
            loanTotal: totalLoanAmount,
            loanMonthlyPayments: activeLoans.fold(0.0, (sum, loan) => sum + loan.monthlyPayment),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Comptes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Obx(() {
                      final accountController = Get.find<AccountController>();
                      final totalBalance = accountController.getTotalBalance();
                      return Text(
                        formatter.format(totalBalance),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: totalBalance >= 0
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error,
                        ),
                      );
                    }),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => Get.toNamed('/accounts'),
                      child: Text(
                        'Voir tout',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (accounts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('Aucun compte disponible'),
              ),
            )
          else
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  return AccountCard(
                    account: account,
                    formatter: formatter,
                    onTap: () => Get.toNamed('/account-details', arguments: account),
                  );
                },
              ),
            ),

          if (activeLoans.isNotEmpty) ...[  
            SectionHeader(
              title: 'Prêts actifs',
              actionText: 'Voir tout',
              onActionPressed: () => Get.toNamed('/loans'),
            ),
            
            ActiveLoansCard(
              loans: activeLoans,
              formatter: formatter,
            ),
          ],

          SectionHeader(
            title: 'Transactions récentes',
            actionText: 'Voir tout',
            onActionPressed: () => Get.toNamed('/expenses'),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  CustomFilterChip(
                    label: 'Tout',
                    route: '/dashboard', // Corrigé de '/home' à '/dashboard'
                    onTap: (route) => Get.toNamed(route), // Changé de offAllNamed à toNamed pour éviter de réinitialiser la pile
                  ),
                  const SizedBox(width: 8),
                  CustomFilterChip(
                    label: 'Dépenses',
                    route: '/expenses',
                    onTap: (route) => Get.toNamed(route), // Changé de offAllNamed à toNamed
                  ),
                  const SizedBox(width: 8),
                  CustomFilterChip(
                    label: 'Revenus',
                    route: '/revenues',
                    onTap: (route) => Get.toNamed(route), // Changé de offAllNamed à toNamed
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          if (recentExpenses.isEmpty && recentRevenues.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Aucune transaction récente',
                  style: TextStyle(color: Theme.of(context).disabledColor),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ...recentExpenses.map(
                    (expense) => TransactionItem(
                      transaction: expense,
                      formatter: formatter,
                    ),
                  ),
                  ...recentRevenues.map(
                    (revenue) => TransactionItem(
                      transaction: revenue,
                      formatter: formatter,
                    ),
                  ),
                ],
              ),
            ),
            
          const SizedBox(height: 80),
        ],
      ),
    );
  }


}
