import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/values/monthly_flow.dart';
import 'package:mybudget/data/model/expense_model.dart';
import 'package:mybudget/data/model/revenue_model.dart';
import 'package:mybudget/data/provider/expenses_provider.dart';
import 'package:mybudget/data/provider/revenues_provider.dart';
import 'package:mybudget/ui/stats/models/category_slice.dart';
import 'package:mybudget/ui/stats/models/category_trend.dart';
import 'package:mybudget/ui/stats/models/stats_range.dart';
import 'package:mybudget/ui/stats/stats_provider.dart';

import 'harness/e2e_harness.dart';

void main() {
  late E2EHarness app;

  final DateTime now = E2EHarness.defaultNow;

  setUp(() async {
    app = await E2EHarness.start(now: now);
    app.container.listen(statsProvider, (_, _) {}, fireImmediately: true);
  });

  tearDown(() => app.dispose());

  Future<void> addExpense({
    required String name,
    required double amount,
    required DateTime startDate,
    Frequency frequency = Frequency.oneTime,
    String categorySlug = 'alimentation.courses',
  }) {
    return app.container
        .read(expenseProvider.notifier)
        .addExpense(
          ExpenseModel.create(
            name: name,
            amount: amount,
            categorySlug: categorySlug,
            startDate: startDate,
            frequency: frequency,
            accountId: 1,
          ),
        );
  }

  Future<void> addRevenue({
    required String name,
    required double amount,
    required DateTime startDate,
    Frequency frequency = Frequency.monthly,
  }) {
    return app.container
        .read(revenueProvider.notifier)
        .addRevenue(
          RevenueModel.create(
            name: name,
            amount: amount,
            startDate: startDate,
            frequency: frequency,
            accountId: 1,
            categorySlug: 'salaire.salaire_net',
          ),
        );
  }

  StatsState stats() => app.container.read(statsProvider);

  group('la répartition du mois', () {
    test('donne à chaque groupe sa part du total', () async {
      await addExpense(
        name: 'Courses',
        amount: 300,
        startDate: DateTime(2026, 6, 2),
      );
      await addExpense(
        name: 'Loyer',
        amount: 900,
        startDate: DateTime(2026, 6, 5),
        categorySlug: 'logement.loyer',
      );

      final List<CategorySlice> slices = stats().slices;

      expect(slices.map((CategorySlice s) => s.groupKey), <String>[
        'logement',
        'alimentation',
      ]);
      expect(slices.first.amount, 900);
      expect(slices.first.share, closeTo(0.75, 0.001));
      expect(slices.last.share, closeTo(0.25, 0.001));
    });

    test('reste vide quand le mois n\'a rien coûté', () async {
      await addExpense(
        name: 'Musée',
        amount: 8,
        startDate: DateTime(2026, 4, 20),
      );

      expect(stats().slices, isEmpty);
    });

    test('classe les parts de la plus grosse à la plus petite', () async {
      await addExpense(
        name: 'Café',
        amount: 3,
        startDate: DateTime(2026, 6, 2),
        categorySlug: 'restauration.cafe',
      );
      await addExpense(
        name: 'Courses',
        amount: 300,
        startDate: DateTime(2026, 6, 3),
      );
      await addExpense(
        name: 'Loyer',
        amount: 900,
        startDate: DateTime(2026, 6, 5),
        categorySlug: 'logement.loyer',
      );

      final List<double> amounts = stats().slices
          .map((CategorySlice s) => s.amount)
          .toList();

      expect(amounts, <double>[900, 300, 3]);
    });
  });

  group('les flux mensuels', () {
    test('couvrent la fenêtre demandée', () async {
      await addRevenue(
        name: 'Salaire',
        amount: 2400,
        startDate: DateTime(2026, 1, 3),
      );

      expect(stats().range, StatsRange.sixMonths);
      expect(stats().flows.length, lessThanOrEqualTo(6));
    });

    test('suivent le changement de fenêtre', () async {
      await addRevenue(
        name: 'Salaire',
        amount: 2400,
        startDate: DateTime(2025, 1, 3),
      );

      app.container
          .read(statsRangeProvider.notifier)
          .select(StatsRange.twelveMonths);

      expect(stats().range, StatsRange.twelveMonths);
      expect(stats().flows, hasLength(12));
    });

    test('séparent revenus et dépenses du même mois', () async {
      await addRevenue(
        name: 'Salaire',
        amount: 2400,
        startDate: DateTime(2026, 6, 3),
      );
      await addExpense(
        name: 'Courses',
        amount: 300,
        startDate: DateTime(2026, 6, 4),
      );

      final MonthlyFlow june = stats().flows.last;

      expect(june.incomes, 2400);
      expect(june.expenses, 300);
    });

    test('le net moyen ne compte que les mois vivants', () async {
      await addExpense(
        name: 'Courses',
        amount: 300,
        startDate: DateTime(2026, 6, 4),
      );

      expect(stats().coveredMonths, 1);
      expect(stats().averageNet, -300);
    });
  });

  group('le taux d\'effort', () {
    test('rapporte les charges récurrentes aux revenus récurrents', () async {
      await addRevenue(
        name: 'Salaire',
        amount: 2000,
        startDate: DateTime(2026, 1, 3),
      );
      await addExpense(
        name: 'Loyer',
        amount: 800,
        startDate: DateTime(2026, 1, 5),
        frequency: Frequency.monthly,
        categorySlug: 'logement.loyer',
      );

      expect(stats().effortRate, closeTo(0.4, 0.001));
      expect(stats().monthlyLeftover, 1200);
    });

    test('n\'existe pas sans revenu récurrent', () async {
      await addExpense(
        name: 'Loyer',
        amount: 800,
        startDate: DateTime(2026, 1, 5),
        frequency: Frequency.monthly,
        categorySlug: 'logement.loyer',
      );

      expect(stats().effortRate, isNull);
    });

    test('ignore une dépense ponctuelle', () async {
      await addRevenue(
        name: 'Salaire',
        amount: 2000,
        startDate: DateTime(2026, 1, 3),
      );
      await addExpense(
        name: 'Cadeau',
        amount: 500,
        startDate: DateTime(2026, 6, 4),
      );

      expect(stats().effortRate, 0);
    });
  });

  group('les mouvements de catégorie', () {
    test('comparent la fenêtre à la précédente', () async {
      await addExpense(
        name: 'Courses janvier',
        amount: 100,
        startDate: DateTime(2025, 12, 4),
      );
      await addExpense(
        name: 'Courses juin',
        amount: 300,
        startDate: DateTime(2026, 6, 4),
      );

      final CategoryTrend groceries = stats().trends.firstWhere(
        (CategoryTrend t) => t.groupKey == 'alimentation',
      );

      expect(groceries.amount, 300);
      expect(groceries.previousAmount, 100);
      expect(groceries.delta, 200);
      expect(groceries.isNew, isFalse);
    });

    test('marquent comme nouvelle une catégorie sans passé', () async {
      await addExpense(
        name: 'Courses',
        amount: 300,
        startDate: DateTime(2026, 6, 4),
      );

      final CategoryTrend groceries = stats().trends.firstWhere(
        (CategoryTrend t) => t.groupKey == 'alimentation',
      );

      expect(groceries.isNew, isTrue);
    });

    test('restent muets sans point de comparaison', () async {
      await addExpense(
        name: 'Courses',
        amount: 300,
        startDate: DateTime(2026, 6, 4),
      );

      expect(stats().hasExpenseComparison, isFalse);
      expect(stats().movers, isEmpty);
    });
  });

  group('l\'ancienneté des données', () {
    test('compte les mois depuis la première trace', () async {
      await addExpense(
        name: 'Vieille dépense',
        amount: 10,
        startDate: DateTime(2026, 4, 4),
      );

      expect(stats().trackedMonths, 3);
      expect(stats().hasHistory, isTrue);
    });

    test('annonce ce qui manque avant d\'avoir un historique', () async {
      await addExpense(
        name: 'Dépense du mois',
        amount: 10,
        startDate: DateTime(2026, 6, 4),
      );

      expect(stats().trackedMonths, 1);
      expect(stats().hasHistory, isFalse);
      expect(stats().monthsUntilHistory, 2);
    });

    test('reste à zéro sans aucune donnée', () async {
      expect(stats().trackedMonths, 0);
      expect(stats().hasHistory, isFalse);
    });
  });
}
