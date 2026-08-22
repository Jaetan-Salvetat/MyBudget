import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/constants/layout_insets.dart';
import 'package:mybudget/ui/common/widgets/month_selector.dart';
import 'package:mybudget/ui/dashboard/dashboard_provider.dart';
import 'package:mybudget/ui/dashboard/widgets/category_breakdown_section.dart';
import 'package:mybudget/ui/dashboard/widgets/dashboard_greeting.dart';
import 'package:mybudget/ui/dashboard/widgets/dashboard_header_balance.dart';
import 'package:mybudget/ui/dashboard/widgets/loan_progress_section.dart';
import 'package:mybudget/ui/dashboard/widgets/upcoming_movements_section.dart';
import 'package:mybudget/ui/expenses/expenses_filter_provider.dart';
import 'package:mybudget/ui/home/home_navigation_provider.dart';
import 'package:mybudget/ui/loans/loan_queries.dart';
import 'package:mybudget/ui/loans/screens/loan_details_screen.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_bar.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_category_zone.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_no_account_dialog.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';
import 'package:mybudget/ui/settings/settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final bool isNested;
  final String fabTag;

  const DashboardScreen({
    this.isNested = false,
    this.fabTag = 'dashboard_fab',
    super.key,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _quickAddFocused = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isNested) {
      return _buildContent(context);
    }
    return FrostedScaffold(body: _buildContent(context));
  }

  void _openCategoryExpenses(String groupKey) {
    ref.read(expensesFilterProvider.notifier).showOnlyGroup(groupKey);
    ref
        .read(homeNavigationProvider.notifier)
        .openTransactions(TransactionsTab.expenses);
  }

  void _openLoans() {
    ref
        .read(homeNavigationProvider.notifier)
        .openTransactions(TransactionsTab.loans);
  }

  void _openLoanDetails(int loanId) {
    final loan = ref
        .read(activeLoansProvider)
        .where((candidate) => candidate.id == loanId)
        .firstOrNull;
    if (loan == null) {
      _openLoans();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoanDetailsScreen(loan: loan)),
    );
  }

  Widget _buildContent(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final quickAddEnabled = ref.watch(quickAddEnabledProvider);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(16, 0, 16, mainFlowBottomInset(context)),
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
            DashboardHeaderBalance(
              typing: _quickAddFocused,
              balance: state.netCashFlow,
              totalIncomes: state.monthlyRevenues,
              totalExpenses: state.totalExpenses,
            ),
            if (quickAddEnabled)
              Padding(
                padding: const EdgeInsets.only(top: FrostedSpacing.sp3),
                child: QuickAddBar(
                  focused: _quickAddFocused,
                  onFocusChanged: (focused) =>
                      setState(() => _quickAddFocused = focused),
                  onNoAccount: () => showQuickAddNoAccountDialog(context),
                ),
              ),
            QuickAddCategoryZone(
              typing: _quickAddFocused,
              breakdown: CategoryBreakdownSection(
                categories: state.categorySummaries,
                onCategoryTap: _openCategoryExpenses,
              ),
            ),
            _CollapsedWhileTyping(
              collapsed: _quickAddFocused,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  UpcomingMovementsSection(
                    movements: state.upcomingMovements,
                  ),
                  LoanProgressSection(
                    summary: state.loanProgress,
                    onSummaryTap: _openLoans,
                    onLoanTap: _openLoanDetails,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clears the screen while the user types : the input and what it understood
/// are the only things that matter then.
class _CollapsedWhileTyping extends StatelessWidget {
  final bool collapsed;
  final Widget child;

  const _CollapsedWhileTyping({required this.collapsed, required this.child});

  @override
  Widget build(BuildContext context) {
    final curve = context.frostedTokens.motion.snappy.curve;

    return AnimatedCrossFade(
      duration: DashboardHeaderBalance.duration,
      sizeCurve: curve,
      alignment: Alignment.topCenter,
      firstChild: child,
      secondChild: const SizedBox(width: double.infinity),
      crossFadeState: collapsed
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
    );
  }
}
