import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/controllers/account_controller.dart';
import 'package:mybudget/core/controllers/expense_controller.dart';
import 'package:mybudget/core/controllers/revenue_controller.dart';
import 'package:mybudget/core/controllers/loan_controller.dart';

import 'package:mybudget/presentation/widgets/dashboard/balance_card.dart';
import 'package:mybudget/presentation/widgets/common/app_scaffold.dart';
import 'package:mybudget/presentation/widgets/dashboard/section_header.dart';
import 'package:mybudget/presentation/widgets/dashboard/category_summary_card.dart';
import 'package:mybudget/presentation/widgets/dashboard/upcoming_payments_card.dart';
import 'package:mybudget/core/extensions/expense_extensions.dart';

class DashboardScreen extends StatelessWidget {
  final bool isNested;
  final String fabTag;

  const DashboardScreen({
    this.isNested = false,
    this.fabTag = 'dashboard_fab',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (isNested) {
      return Obx(() => _buildDashboard(context));
    }

    return AppScaffold(
      title: 'MyBudget',
      child: Scaffold(body: Obx(() => _buildDashboard(context))),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final accountController = Get.find<AccountController>();
    final expenseController = Get.find<ExpenseController>();
    final revenueController = Get.find<RevenueController>();
    final loanController = Get.find<LoanController>();

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
            loanMonthlyPayments: activeLoans.fold(
              0.0,
              (sum, loan) => sum + loan.monthlyPayment,
            ),
          ),

          const SectionHeader(title: 'Paiements à venir'),

          UpcomingPaymentsCard(formatter: formatter),

          const SizedBox(height: 16),

          const SectionHeader(title: 'Dépenses par catégorie'),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Obx(() {
              final categoryExpenses =
                  expenseController.getExpensesByCategory();
              return CategorySummaryCard(
                categories: categoryExpenses,
                formatter: formatter,
              );
            }),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
