import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/entities/monthly_flow.dart';
import 'package:mybudget/ui/stats/models/stats_range.dart';
import 'package:mybudget/ui/stats/stats_provider.dart';

void main() {
  StatsState stateOf({
    double totalIncomes = 0,
    double totalExpenses = 0,
    int coveredMonths = 0,
    double previousIncomes = 0,
    double previousExpenses = 0,
    int previousCoveredMonths = 0,
    double monthlyRecurringExpenses = 0,
    double monthlyRecurringIncomes = 0,
    double annualRecurringExpenses = 0,
    double annualRecurringIncomes = 0,
  }) => StatsState(
    range: StatsRange.sixMonths,
    flows: const <MonthlyFlow>[],
    totalIncomes: totalIncomes,
    totalExpenses: totalExpenses,
    coveredMonths: coveredMonths,
    previousIncomes: previousIncomes,
    previousExpenses: previousExpenses,
    previousCoveredMonths: previousCoveredMonths,
    monthlyRecurringExpenses: monthlyRecurringExpenses,
    monthlyRecurringIncomes: monthlyRecurringIncomes,
    annualRecurringExpenses: annualRecurringExpenses,
    annualRecurringIncomes: annualRecurringIncomes,
    trends: const [],
    slices: const [],
    trackedMonths: coveredMonths,
  );

  group('net flow', () {
    test('averages the net over the months actually tracked', () {
      final state = stateOf(
        totalIncomes: 4000,
        totalExpenses: 3000,
        coveredMonths: 2,
      );

      expect(state.averageNet, 500);
    });

    test('averages nothing when no month is tracked yet', () {
      final state = stateOf();

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
  });

  group('effort rate', () {
    test('rates the fixed charges against the recurring income', () {
      final state = stateOf(
        monthlyRecurringExpenses: 600,
        monthlyRecurringIncomes: 2000,
      );

      expect(state.effortRate, closeTo(0.3, 0.001));
      expect(state.monthlyLeftover, 1400);
    });

    test('goes past one when the fixed charges eat the income', () {
      final state = stateOf(
        monthlyRecurringExpenses: 2200,
        monthlyRecurringIncomes: 2000,
      );

      expect(state.effortRate, closeTo(1.1, 0.001));
      expect(state.monthlyLeftover, -200);
    });

    test('has no rate without recurring income', () {
      final state = stateOf(monthlyRecurringExpenses: 600);

      expect(state.effortRate, isNull);
      expect(state.annualEffortRate, isNull);
    });

    test('rates the twelve month window on its own totals', () {
      final state = stateOf(
        monthlyRecurringExpenses: 600,
        monthlyRecurringIncomes: 2000,
        annualRecurringExpenses: 7500,
        annualRecurringIncomes: 24000,
      );

      expect(state.annualEffortRate, closeTo(0.3125, 0.0001));
    });
  });
}
