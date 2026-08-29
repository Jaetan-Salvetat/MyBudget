import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/constants/layout_insets.dart';
import 'package:mybudget/core/providers/transaction_filter_provider.dart';
import 'package:mybudget/ui/common/widgets/month_selector.dart';
import 'package:mybudget/ui/home/home_navigation_provider.dart';
import 'package:mybudget/ui/loans/loan_queries.dart';
import 'package:mybudget/ui/loans/screens/loan_details_screen.dart';
import 'package:mybudget/ui/settings/settings_screen.dart';
import 'package:mybudget/ui/stats/stats_provider.dart';
import 'package:mybudget/ui/stats/widgets/category_breakdown_section.dart';
import 'package:mybudget/ui/stats/widgets/hero_balance_card.dart';
import 'package:mybudget/ui/stats/widgets/loan_progress_section.dart';
import 'package:mybudget/ui/stats/widgets/stats_greeting.dart';
import 'package:mybudget/ui/stats/widgets/upcoming_movements_section.dart';

/// The month read in full : balance, breakdown, what is coming. The capture
/// screen owns the present, this one owns the period.
class StatsScreen extends ConsumerWidget {
  final bool isNested;

  const StatsScreen({this.isNested = false, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = _Content(
      onCategoryTap: (groupKey) => _openCategoryExpenses(ref, groupKey),
      onLoansTap: () => _openLoans(ref),
      onLoanTap: (loanId) => _openLoanDetails(context, ref, loanId),
      onSettingsTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ),
    );

    if (isNested) return content;
    return FrostedScaffold(body: content);
  }

  void _openCategoryExpenses(WidgetRef ref, String groupKey) {
    ref.read(expensesFilterProvider.notifier).showOnlyGroup(groupKey);
    ref
        .read(homeNavigationProvider.notifier)
        .openTransactions(TransactionsTab.expenses);
  }

  void _openLoans(WidgetRef ref) {
    ref
        .read(homeNavigationProvider.notifier)
        .openTransactions(TransactionsTab.loans);
  }

  void _openLoanDetails(BuildContext context, WidgetRef ref, int loanId) {
    final loan = ref
        .read(activeLoansProvider)
        .where((candidate) => candidate.id == loanId)
        .firstOrNull;
    if (loan == null) {
      _openLoans(ref);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoanDetailsScreen(loan: loan)),
    );
  }
}

class _Content extends ConsumerWidget {
  final ValueChanged<String> onCategoryTap;
  final VoidCallback onLoansTap;
  final ValueChanged<int> onLoanTap;
  final VoidCallback onSettingsTap;

  const _Content({
    required this.onCategoryTap,
    required this.onLoansTap,
    required this.onLoanTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(statsProvider);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          kMainFlowGutter,
          0,
          kMainFlowGutter,
          mainFlowBottomInset(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatsGreeting(onSettingsTap: onSettingsTap),
            const MonthSelector(),
            HeroBalanceCard(
              balance: state.netCashFlow,
              totalIncomes: state.monthlyRevenues,
              totalExpenses: state.totalExpenses,
            ),
            CategoryBreakdownSection(
              categories: state.categorySummaries,
              onCategoryTap: onCategoryTap,
            ),
            UpcomingMovementsSection(movements: state.upcomingMovements),
            LoanProgressSection(
              summary: state.loanProgress,
              onSummaryTap: onLoansTap,
              onLoanTap: onLoanTap,
            ),
          ],
        ),
      ),
    );
  }
}
