import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/domain/entities/account.dart';
import 'package:mybudget/domain/entities/expense.dart';
import 'package:mybudget/domain/entities/revenue.dart';
import 'package:mybudget/data/models/loan_model.dart';
import 'package:mybudget/core/controllers/account_controller.dart';
import 'package:mybudget/core/controllers/expense_controller.dart';
import 'package:mybudget/core/controllers/revenue_controller.dart';
import 'package:mybudget/core/controllers/loan_controller.dart';

import 'package:mybudget/presentation/widgets/common/financial_card.dart';
import 'package:mybudget/presentation/widgets/common/filter_chip.dart';
import 'package:mybudget/presentation/widgets/dashboard/balance_card.dart';
import 'package:mybudget/presentation/widgets/dashboard/account_card.dart';
import 'package:mybudget/presentation/widgets/dashboard/transaction_item.dart';
import 'package:mybudget/presentation/widgets/dashboard/section_header.dart';
import 'package:mybudget/presentation/widgets/dashboard/empty_state.dart';
import 'package:mybudget/presentation/widgets/common/app_scaffold.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accountController = Get.find<AccountController>();
    final expenseController = Get.find<ExpenseController>();
    final revenueController = Get.find<RevenueController>();
    final loanController = Get.find<LoanController>();
    
    final accounts = accountController.accounts;
    final expenses = expenseController.expenses;
    final revenues = revenueController.revenues;
    final loans = loanController.loans;

    final monthlyExpenses = _calculateMonthlyExpenses(expenses);
    final monthlyRevenues = _calculateMonthlyRevenues(revenues);
    final netCashFlow = _calculateNetCashFlow(monthlyRevenues, monthlyExpenses);
    final double savingsRate =
        monthlyRevenues > 0 ? (netCashFlow / monthlyRevenues) * 100 : 0;

    return AppScaffold(
      title: 'MyBudget',
      child: Scaffold(
        body: Obx(() => 
          accounts.isEmpty && expenses.isEmpty && revenues.isEmpty
            ? EmptyDashboardState(
                onSetupPressed: () => Get.toNamed('/accounts'),
              )
            : _buildDashboard(
                context,
                netCashFlow,
                monthlyExpenses,
                monthlyRevenues,
                netCashFlow,
                savingsRate,
                accounts,
                expenses,
                revenues,
                loans,
              ),
        ),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    double netCashFlow,
    double monthlyExpenses,
    double monthlyRevenues,
    double netFlow,
    double savingsRate,
    List<Account> accounts,
    List<Expense> expenses,
    List<Revenue> revenues,
    RxList<LoanModel> loans,
  ) {
    final NumberFormat formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
    );

    // Création des listes pour les transactions récentes limitées à 3
    final recentExpenses = expenses.take(3).toList();
    final recentRevenues = revenues.take(3).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 100), // Espace pour l'AppBar
          // Carte de solde total
          BalanceCard(
            balance: netCashFlow,
            netFlow: netFlow,
            savingsRate: savingsRate,
            formatter: formatter,
          ),

          // Résumé financier
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 5),
            child: Row(
              children: [
                Expanded(
                  child: FinancialCard(
                    title: 'Dépenses',
                    amount: monthlyExpenses,
                    formatter: formatter,
                    icon: Icons.arrow_downward,
                    color: Theme.of(context).colorScheme.error,
                    iconBackgroundColor: Theme.of(
                      context,
                    ).colorScheme.error.withOpacity(0.1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FinancialCard(
                    title: 'Revenus',
                    amount: monthlyRevenues,
                    formatter: formatter,
                    icon: Icons.arrow_upward,
                    color: Colors.green.shade700,
                    iconBackgroundColor: Colors.green.shade700.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),

          // En-tête des comptes
          SectionHeader(
            title: 'Comptes',
            actionText: 'Voir tout',
            onActionPressed: () => Navigator.pushNamed(context, '/accounts'),
          ),

          // Liste des comptes
          SizedBox(
            height: 130,
            child:
                accounts.isEmpty
                    ? Center(
                      child: Text(
                        'Aucun compte',
                        style: TextStyle(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.only(left: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: accounts.length,
                      itemBuilder: (context, index) {
                        return AccountCard(
                          account: accounts[index],
                          formatter: formatter,
                          onTap: () => Get.toNamed('/accounts'),
                        );
                      },
                    ),
          ),

          // Section des emprunts
          if (loans.isNotEmpty) ...[  
            SectionHeader(
              title: 'Mes emprunts',
              actionText: 'Voir tout',
              onActionPressed: () => Get.toNamed('/loans'),
            ),
            
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: loans.length > 3 ? 3 : loans.length,
                itemBuilder: (context, index) {
                  final loan = loans[index];
                  final progress = loan.getProgressPercentage();
                  final remainingAmount = loan.getRemainingAmount();
                  
                  return Container(
                    width: 220,
                    margin: EdgeInsets.only(
                      right: 12, 
                      bottom: 4,
                      left: index == 0 ? 0 : 0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Get.toNamed('/loan-details', arguments: loan),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      loan.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    ),
                                    child: Text(
                                      '${(progress * 100).toInt()}%',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.account_balance,
                                    size: 14,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    loan.lenderName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: progress,
                                minHeight: 4,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    formatter.format(remainingAmount),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    '${formatter.format(loan.monthlyPayment)}/mois',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // En-tête des transactions
          SectionHeader(
            title: 'Transactions récentes',
            actionText: 'Voir tout',
            onActionPressed: () => Get.toNamed('/expenses'),
          ),

          // Filtres de transactions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  CustomFilterChip(
                    label: 'Tout',
                    route: '/home',
                    onTap: (route) => Get.offAllNamed(route),
                  ),
                  const SizedBox(width: 8),
                  CustomFilterChip(
                    label: 'Dépenses',
                    route: '/expenses',
                    onTap: (route) => Get.offAllNamed(route),
                  ),
                  const SizedBox(width: 8),
                  CustomFilterChip(
                    label: 'Revenus',
                    route: '/revenues',
                    onTap: (route) => Get.offAllNamed(route),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Liste des transactions récentes
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
                  // Dépenses récentes
                  ...recentExpenses.map(
                    (expense) => TransactionItem(
                      transaction: expense,
                      formatter: formatter,
                    ),
                  ),

                  // Revenus récents
                  ...recentRevenues.map(
                    (revenue) => TransactionItem(
                      transaction: revenue,
                      formatter: formatter,
                    ),
                  ),
                ],
              ),
            ),

          // Padding pour éviter que le contenu soit caché par la barre de navigation
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  double _calculateNetCashFlow(double revenues, double expenses) {
    return revenues - expenses;
  }

  double _calculateMonthlyExpenses(List<Expense> expenses) {
    if (expenses.isEmpty) return 0.0;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return expenses
        .where(
          (expense) =>
              expense.date.isAfter(startOfMonth) &&
              expense.date.isBefore(endOfMonth),
        )
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double _calculateMonthlyRevenues(List<Revenue> revenues) {
    if (revenues.isEmpty) return 0.0;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return revenues
        .where(
          (revenue) =>
              revenue.date.isAfter(startOfMonth) &&
              revenue.date.isBefore(endOfMonth),
        )
        .fold(0.0, (sum, revenue) => sum + revenue.amount);
  }
}
