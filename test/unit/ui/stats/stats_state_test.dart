import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/entities/monthly_flow.dart';
import 'package:mybudget/ui/stats/models/stats_range.dart';
import 'package:mybudget/ui/stats/stats_provider.dart';

void main() {
  StatsState stateOf({
    required double totalIncomes,
    required double totalExpenses,
    required int coveredMonths,
    double previousIncomes = 0,
    double previousExpenses = 0,
    int previousCoveredMonths = 0,
  }) => StatsState(
    range: StatsRange.sixMonths,
    flows: const <MonthlyFlow>[],
    totalIncomes: totalIncomes,
    totalExpenses: totalExpenses,
    coveredMonths: coveredMonths,
    previousIncomes: previousIncomes,
    previousExpenses: previousExpenses,
    previousCoveredMonths: previousCoveredMonths,
    recurringExpenses: 0,
    previousRecurringExpenses: 0,
    categories: const [],
    trackedMonths: coveredMonths,
  );

  test('averages the net over the months actually tracked', () {
    final state = stateOf(
      totalIncomes: 4000,
      totalExpenses: 3000,
      coveredMonths: 2,
    );

    expect(state.averageNet, 500);
  });

  test('averages nothing when no month is tracked yet', () {
    final state = stateOf(totalIncomes: 0, totalExpenses: 0, coveredMonths: 0);

    expect(state.averageNet, 0);
    expect(state.netDelta, 0);
  });

  test('compares two windows of different lengths month for month', () {
    final state = stateOf(
      totalIncomes: 6000,
      totalExpenses: 4500,
      coveredMonths: 3,
      previousIncomes: 2000,
      previousExpenses: 1000,
      previousCoveredMonths: 2,
    );

    expect(state.previousAverageNet, 500);
    expect(state.netDelta, 0);
  });
}
