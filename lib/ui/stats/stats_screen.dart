import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/constants/layout_insets.dart';
import 'package:mybudget/core/providers/selected_month_provider.dart';
import 'package:mybudget/core/providers/transaction_filter_provider.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/common/widgets/solid_card.dart';
import 'package:mybudget/ui/home/home_navigation_provider.dart';
import 'package:mybudget/ui/stats/stats_provider.dart';
import 'package:mybudget/ui/stats/widgets/category_breakdown_section.dart';
import 'package:mybudget/ui/stats/widgets/category_movers_section.dart';
import 'package:mybudget/ui/stats/widgets/effort_rate_section.dart';
import 'package:mybudget/ui/stats/widgets/monthly_flow_section.dart';
import 'package:mybudget/ui/stats/widgets/stats_header.dart';

class StatsScreen extends ConsumerWidget {
  final bool isNested;

  const StatsScreen({this.isNested = false, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = _Content(
      onCategoryTap: (groupKey) => _openCategoryExpenses(ref, groupKey),
      onMonthTap: (month) => _openMonth(ref, month),
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

  void _openMonth(WidgetRef ref, DateTime month) {
    ref.read(selectedMonthProvider.notifier).setMonth(month);
    ref
        .read(homeNavigationProvider.notifier)
        .openTransactions(TransactionsTab.expenses);
  }
}

class _Content extends ConsumerWidget {
  final ValueChanged<String> onCategoryTap;
  final ValueChanged<DateTime> onMonthTap;

  const _Content({required this.onCategoryTap, required this.onMonthTap});

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
            const StatsHeader(),
            MonthlyFlowSection(
              flows: state.flows,
              averageNet: state.averageNet,
              netDelta: state.netDelta,
              hasComparison: state.hasComparison,
              onMonthTap: onMonthTap,
            ),
            if (!state.hasHistory)
              _YoungBudgetNotice(monthsToGo: state.monthsUntilHistory),
            EffortRateSection(
              rate: state.effortRate,
              annualRate: state.annualEffortRate,
              recurringExpenses: state.monthlyRecurringExpenses,
              leftover: state.monthlyLeftover,
            ),
            CategoryMoversSection(
              movers: state.movers,
              comparedMonths: state.range.months,
              onCategoryTap: onCategoryTap,
            ),
            CategoryBreakdownSection(
              categories: state.categories,
              onCategoryTap: onCategoryTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _YoungBudgetNotice extends StatelessWidget {
  final int monthsToGo;

  const _YoungBudgetNotice({required this.monthsToGo});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SolidCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Text(
          monthsToGo > 1
              ? 'Encore $monthsToGo mois de suivi avant que les comparaisons soient parlantes.'
              : 'Encore un mois de suivi avant que les comparaisons soient parlantes.',
          style: AppTextStyles.mono(
            fontSize: 10.5,
            lineHeight: 15,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
