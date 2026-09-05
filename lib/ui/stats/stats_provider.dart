import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/entities/monthly_flow.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/services/stats_calculator.dart';
import 'package:mybudget/ui/expenses/expense_queries.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/ui/revenues/revenue_queries.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';
import 'package:mybudget/ui/stats/models/category_trend.dart';
import 'package:mybudget/ui/stats/models/stats_range.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stats_provider.g.dart';

class StatsState {
  static const int minimumTrackedMonths = 3;

  final StatsRange range;
  final List<MonthlyFlow> flows;
  final double totalIncomes;
  final double totalExpenses;
  final double previousIncomes;
  final double previousExpenses;
  final double recurringExpenses;
  final double previousRecurringExpenses;
  final List<CategoryTrend> categories;
  final int trackedMonths;

  const StatsState({
    required this.range,
    required this.flows,
    required this.totalIncomes,
    required this.totalExpenses,
    required this.previousIncomes,
    required this.previousExpenses,
    required this.recurringExpenses,
    required this.previousRecurringExpenses,
    required this.categories,
    required this.trackedMonths,
  });

  double get averageNet => (totalIncomes - totalExpenses) / range.months;

  double get previousAverageNet =>
      (previousIncomes - previousExpenses) / range.months;

  double get netDelta => averageNet - previousAverageNet;

  double get variableExpenses => totalExpenses - recurringExpenses;

  double get recurringShare =>
      totalExpenses <= 0 ? 0 : recurringExpenses / totalExpenses;

  double get previousRecurringShare =>
      previousExpenses <= 0 ? 0 : previousRecurringExpenses / previousExpenses;

  double get recurringShareDelta => recurringShare - previousRecurringShare;

  bool get hasHistory => trackedMonths >= minimumTrackedMonths;

  bool get hasComparison => previousExpenses > 0 || previousIncomes > 0;

  int get monthsUntilHistory => minimumTrackedMonths - trackedMonths;

  List<CategoryTrend> get movers {
    final moved = categories.where((trend) => trend.delta.abs() >= 1).toList();
    moved.sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));
    return moved;
  }
}

@Riverpod(keepAlive: true)
class StatsRangeNotifier extends _$StatsRangeNotifier {
  @override
  StatsRange build() => StatsRange.sixMonths;

  void select(StatsRange range) => state = range;
}

@Riverpod(keepAlive: true)
class StatsNotifier extends _$StatsNotifier {
  @override
  StatsState build() {
    final range = ref.watch(statsRangeProvider);
    final resolver = ref.watch(categoryDisplayResolverProvider).value;

    final calculator = StatsCalculator(
      expenses: ref.watch(expenseHistoryProvider),
      revenues: ref.watch(revenueHistoryProvider),
      loans: ref.watch(loanProvider).value ?? const [],
      resolver: resolver,
    );

    final now = DateTime.now();
    final anchor = DateTime(now.year, now.month);
    final months = StatsCalculator.monthsEndingAt(anchor, range.months);
    final earlier = StatsCalculator.monthsEndingAt(
      DateTime(anchor.year, anchor.month - range.months),
      range.months,
    );

    final flows = calculator.flowsOver(months);
    final previousFlows = calculator.flowsOver(earlier);

    final totals = calculator.expensesByGroupOver(months);
    final previousTotals = calculator.expensesByGroupOver(earlier);
    final totalExpenses = flows.fold(0.0, (sum, flow) => sum + flow.expenses);

    return StatsState(
      range: range,
      flows: flows,
      totalIncomes: flows.fold(0.0, (sum, flow) => sum + flow.incomes),
      totalExpenses: totalExpenses,
      previousIncomes: previousFlows.fold(
        0.0,
        (sum, flow) => sum + flow.incomes,
      ),
      previousExpenses: previousFlows.fold(
        0.0,
        (sum, flow) => sum + flow.expenses,
      ),
      recurringExpenses: calculator.recurringExpensesOver(months),
      previousRecurringExpenses: calculator.recurringExpensesOver(earlier),
      categories: _buildTrends(totals, previousTotals, totalExpenses, resolver),
      trackedMonths: _trackedMonths(calculator.earliestMonth(), anchor),
    );
  }

  List<CategoryTrend> _buildTrends(
    Map<String, double> totals,
    Map<String, double> previousTotals,
    double totalExpenses,
    CategoryDisplayResolver? resolver,
  ) {
    if (totalExpenses <= 0 || resolver == null) return const [];

    final trends = <CategoryTrend>[];
    totals.forEach((groupKey, amount) {
      final group =
          resolver.resolveGroup(groupKey) ??
          resolver.uncategorized(TransactionType.expense);
      trends.add(
        CategoryTrend(
          groupKey: groupKey,
          label: group.label,
          color: Color(group.color),
          amount: amount,
          previousAmount: previousTotals[groupKey] ?? 0,
          share: amount / totalExpenses,
        ),
      );
    });
    trends.sort((a, b) => b.amount.compareTo(a.amount));
    return trends;
  }

  int _trackedMonths(DateTime? earliest, DateTime anchor) {
    if (earliest == null) return 0;
    if (earliest.isAfter(anchor)) return 0;
    return (anchor.year - earliest.year) * 12 +
        (anchor.month - earliest.month) +
        1;
  }
}
