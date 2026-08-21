import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/models/expense_filter_data.dart';
import 'package:mybudget/ui/common/widgets/month_selector.dart';
import 'package:mybudget/ui/dashboard/dashboard_provider.dart';
import 'package:mybudget/ui/dashboard/widgets/category_breakdown_section.dart';
import 'package:mybudget/ui/dashboard/widgets/dashboard_greeting.dart';
import 'package:mybudget/ui/dashboard/widgets/hero_balance_card.dart';
import 'package:mybudget/ui/dashboard/widgets/loan_progress_section.dart';
import 'package:mybudget/ui/dashboard/widgets/upcoming_movements_section.dart';
import 'package:mybudget/ui/expenses/expenses_screen.dart';
import 'package:mybudget/ui/settings/settings_screen.dart';

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
      return _buildContent(context, ref);
    }
    return FrostedScaffold(child: _buildContent(context, ref));
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 180),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardGreeting(
              onSettingsTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            const MonthSelector(),
            HeroBalanceCard(
              balance: state.netCashFlow,
              totalIncomes: state.monthlyRevenues,
              totalExpenses: state.totalExpenses,
            ),
            UpcomingMovementsSection(movements: state.upcomingMovements),
            CategoryBreakdownSection(
              categories: state.categorySummaries,
              onCategoryTap: (groupKey) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExpensesScreen(
                    standalone: true,
                    initialFilter: ExpenseFilterData(groupKeys: [groupKey]),
                  ),
                ),
              ),
            ),
            LoanProgressSection(summary: state.loanProgress),
          ],
        ),
      ),
    );
  }
}
