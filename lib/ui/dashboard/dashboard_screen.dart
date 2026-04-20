import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/ui/dashboard/dashboard_provider.dart';
import 'package:mybudget/ui/dashboard/widgets/balance_card.dart';
import 'package:mybudget/ui/dashboard/widgets/upcoming_payments_card.dart';
import 'package:mybudget/models/expense_filter_data.dart';
import 'package:mybudget/ui/expenses/expenses_screen.dart';
import 'package:mybudget/ui/dashboard/widgets/category_summary_card.dart';
import 'package:mybudget/ui/common/widgets/month_selector.dart';

class DashboardScreen extends ConsumerWidget {
  final bool isNested;
  final String fabTag;

  const DashboardScreen({
    this.isNested = false,
    this.fabTag = 'dashboard_fab',
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isNested) {
      return _buildDashboardContent(context, ref);
    }

    return FrostedScaffold(child: _buildDashboardContent(context, ref));
  }

  Widget _buildDashboardContent(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);

    final netCashFlow = dashboardState.netCashFlow;
    final savingsRate = dashboardState.savingsRate;
    final totalLoanAmount = dashboardState.totalLoanAmount;
    final totalExpenses = dashboardState.totalExpenses;
    final monthlyRevenues = dashboardState.monthlyRevenues;
    final totalMonthlyLoanPayments = dashboardState.totalMonthlyLoanPayments;
    final categorySummaries = dashboardState.categorySummaries;

    final NumberFormat formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 120),
          const MonthSelector(),

          BalanceCard(
            balance: netCashFlow,
            netFlow: totalLoanAmount,
            savingsRate: savingsRate,
            formatter: formatter,
            expenses: totalExpenses,
            revenues: monthlyRevenues,
            loanTotal: totalLoanAmount,
            loanMonthlyPayments: totalMonthlyLoanPayments,
            recurringExpenses: dashboardState.recurringExpenses,
            oneTimeExpenses: dashboardState.oneTimeExpenses,
            recurringRevenues: dashboardState.recurringRevenues,
            oneTimeRevenues: dashboardState.oneTimeRevenues,
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Paiements à venir',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          UpcomingPaymentsCard(formatter: formatter),

          const SizedBox(height: 16),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Dépenses par catégorie',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CategorySummaryCard(
              categories: categorySummaries,
              formatter: formatter,
              onCategoryTap: (categoryId) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExpensesScreen(
                    standalone: true,
                    initialFilter: ExpenseFilterData(categoryIds: [categoryId]),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
