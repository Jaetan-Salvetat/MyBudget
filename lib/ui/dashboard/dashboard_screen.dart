import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/ui/dashboard/dashboard_viewmodel.dart';
import 'package:mybudget/ui/dashboard/widgets/balance_card.dart';
import 'package:mybudget/ui/dashboard/widgets/upcoming_payments_card.dart';
import 'package:mybudget/ui/dashboard/widgets/category_summary_card.dart';

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
      return _buildDashboardContent(context);
    }

    return Scaffold(body: _buildDashboardContent(context));
  }

  Widget _buildDashboardContent(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, dashboardVM, child) {
        final netCashFlow = dashboardVM.netCashFlow;
        final savingsRate = dashboardVM.savingsRate;
        final totalLoanAmount = dashboardVM.totalLoanAmount;
        final totalExpenses = dashboardVM.totalExpenses;
        final monthlyRevenues = dashboardVM.monthlyRevenues;
        final totalMonthlyLoanPayments = dashboardVM.totalMonthlyLoanPayments;
        final categorySummaries = dashboardVM.categorySummaries;

        final NumberFormat formatter = NumberFormat.currency(
          locale: 'fr_FR',
          symbol: '€',
        );

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 100),

              BalanceCard(
                balance: netCashFlow,
                netFlow: totalLoanAmount,
                savingsRate: savingsRate,
                formatter: formatter,
                expenses: totalExpenses,
                revenues: monthlyRevenues,
                loanTotal: totalLoanAmount,
                loanMonthlyPayments: totalMonthlyLoanPayments,
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
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }
}
