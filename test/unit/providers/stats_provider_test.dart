import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/loan_event_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';
import 'package:mybudget/ui/stats/models/stats_range.dart';
import 'package:mybudget/ui/stats/stats_provider.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockLoanRepository extends Mock implements LoanRepository {}

class MockLoanEventRepository extends Mock implements LoanEventRepository {}

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAccountRepository mockAccountRepo;
  late MockExpenseRepository mockExpenseRepo;
  late MockRevenueRepository mockRevenueRepo;
  late MockLoanRepository mockLoanRepo;
  late MockLoanEventRepository mockLoanEventRepo;
  late MockCategoryOverrideRepository mockCategoryOverrideRepo;

  final DateTime thisMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  DateTime monthsAgo(int count) =>
      DateTime(thisMonth.year, thisMonth.month - count, 5);

  setUp(() {
    mockAccountRepo = MockAccountRepository();
    mockExpenseRepo = MockExpenseRepository();
    mockRevenueRepo = MockRevenueRepository();
    mockLoanRepo = MockLoanRepository();
    mockLoanEventRepo = MockLoanEventRepository();
    mockCategoryOverrideRepo = MockCategoryOverrideRepository();

    when(() => mockAccountRepo.getAll()).thenReturn([]);
    when(() => mockExpenseRepo.getAll()).thenReturn([]);
    when(() => mockExpenseRepo.getActive()).thenReturn([]);
    when(() => mockExpenseRepo.getClosed()).thenReturn([]);
    when(() => mockRevenueRepo.getAll()).thenReturn([]);
    when(() => mockRevenueRepo.getActive()).thenReturn([]);
    when(() => mockRevenueRepo.getClosed()).thenReturn([]);
    when(() => mockLoanRepo.getAll()).thenReturn([]);
    when(() => mockLoanEventRepo.getAll()).thenReturn([]);
    when(() => mockCategoryOverrideRepo.getAll()).thenReturn({});
  });

  ProviderContainer containerWith({
    List<ExpenseModel> expenses = const [],
    List<RevenueModel> revenues = const [],
  }) {
    when(() => mockExpenseRepo.getAll()).thenReturn([...expenses]);
    when(() => mockExpenseRepo.getActive()).thenReturn([...expenses]);
    when(() => mockRevenueRepo.getAll()).thenReturn([...revenues]);
    when(() => mockRevenueRepo.getActive()).thenReturn([...revenues]);

    final container = ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(mockAccountRepo),
        expenseRepositoryProvider.overrideWithValue(mockExpenseRepo),
        revenueRepositoryProvider.overrideWithValue(mockRevenueRepo),
        loanRepositoryProvider.overrideWithValue(mockLoanRepo),
        loanEventRepositoryProvider.overrideWithValue(mockLoanEventRepo),
        categoryOverrideRepositoryProvider.overrideWithValue(
          mockCategoryOverrideRepo,
        ),
      ],
    );
    addTearDown(container.dispose);

    return container;
  }

  Future<void> warmUp(ProviderContainer container) async {
    await container.read(expenseProvider.future);
    await container.read(revenueProvider.future);
    await container.read(loanProvider.future);
    await container.read(categoryDisplayResolverProvider.future);
  }

  Future<StatsState> readState({
    List<ExpenseModel> expenses = const [],
    List<RevenueModel> revenues = const [],
    StatsRange range = StatsRange.sixMonths,
  }) async {
    final container = containerWith(expenses: expenses, revenues: revenues);
    await warmUp(container);

    container.read(statsRangeProvider.notifier).select(range);
    return container.read(statsProvider);
  }

  ExpenseModel expense({
    required double amount,
    required DateTime startDate,
    Frequency frequency = Frequency.monthly,
    String? categorySlug,
  }) => ExpenseModel.create(
    name: 'Dépense',
    amount: amount,
    accountId: 1,
    startDate: startDate,
    frequency: frequency,
    categorySlug: categorySlug,
  );

  RevenueModel revenue({
    required double amount,
    required DateTime startDate,
    Frequency frequency = Frequency.monthly,
  }) => RevenueModel.create(
    name: 'Revenu',
    amount: amount,
    accountId: 1,
    startDate: startDate,
    frequency: frequency,
  );

  group('window', () {
    test('holds one flow per month of the selected range', () async {
      final state = await readState(range: StatsRange.twelveMonths);

      expect(state.flows, hasLength(12));
      expect(state.flows.last.month, thisMonth);
      expect(
        state.flows.first.month,
        DateTime(thisMonth.year, thisMonth.month - 11),
      );
    });

    test('averages the net flow over the range', () async {
      final state = await readState(
        expenses: [expense(amount: 400, startDate: monthsAgo(11))],
        revenues: [revenue(amount: 1000, startDate: monthsAgo(11))],
      );

      expect(state.averageNet, closeTo(600, 0.01));
    });

    test('compares the range with the one right before it', () async {
      final state = await readState(
        expenses: [
          expense(amount: 100, startDate: monthsAgo(11)),
          expense(
            amount: 600,
            startDate: monthsAgo(1),
            frequency: Frequency.oneTime,
          ),
        ],
        revenues: [revenue(amount: 1000, startDate: monthsAgo(11))],
      );

      expect(state.hasComparison, isTrue);
      expect(state.previousAverageNet, closeTo(900, 0.01));
      expect(state.netDelta, closeTo(-100, 0.01));
    });

    test('has no comparison when nothing precedes the range', () async {
      final state = await readState(
        expenses: [expense(amount: 100, startDate: monthsAgo(2))],
      );

      expect(state.hasComparison, isFalse);
    });
  });

  group('effort rate', () {
    test('rates this month fixed charges against recurring income', () async {
      final state = await readState(
        expenses: [
          expense(amount: 600, startDate: monthsAgo(5)),
          expense(
            amount: 900,
            startDate: monthsAgo(0),
            frequency: Frequency.oneTime,
          ),
        ],
        revenues: [revenue(amount: 2000, startDate: monthsAgo(5))],
      );

      expect(state.monthlyRecurringExpenses, 600);
      expect(state.monthlyRecurringIncomes, 2000);
      expect(state.effortRate, closeTo(0.3, 0.001));
      expect(state.monthlyLeftover, 1400);
    });

    test('leaves one-off income out of the rate', () async {
      final state = await readState(
        expenses: [expense(amount: 600, startDate: monthsAgo(5))],
        revenues: [
          revenue(amount: 2000, startDate: monthsAgo(5)),
          revenue(
            amount: 1000,
            startDate: monthsAgo(0),
            frequency: Frequency.oneTime,
          ),
        ],
      );

      expect(state.monthlyRecurringIncomes, 2000);
      expect(state.effortRate, closeTo(0.3, 0.001));
    });

    test('has no rate without recurring income', () async {
      final state = await readState(
        expenses: [expense(amount: 600, startDate: monthsAgo(5))],
      );

      expect(state.effortRate, isNull);
      expect(state.annualEffortRate, isNull);
    });

    test('carries annual charges in the twelve month rate only', () async {
      final state = await readState(
        expenses: [
          expense(amount: 600, startDate: monthsAgo(5)),
          expense(
            amount: 300,
            startDate: monthsAgo(8),
            frequency: Frequency.annual,
          ),
        ],
        revenues: [revenue(amount: 2000, startDate: monthsAgo(5))],
      );

      expect(state.annualRecurringExpenses, 3900);
      expect(state.annualRecurringIncomes, 12000);
      expect(state.effortRate, closeTo(0.3, 0.001));
      expect(state.annualEffortRate, closeTo(0.325, 0.001));
    });

    test('leaves the quiet months out of the twelve month rate', () async {
      final state = await readState(
        expenses: [expense(amount: 600, startDate: monthsAgo(3))],
        revenues: [revenue(amount: 2000, startDate: monthsAgo(3))],
      );

      expect(state.annualRecurringExpenses, 2400);
      expect(state.annualRecurringIncomes, 8000);
      expect(state.annualEffortRate, state.effortRate);
    });

    test('keeps the twelve month rate when the range is six months', () async {
      final state = await readState(
        expenses: [
          expense(
            amount: 300,
            startDate: monthsAgo(8),
            frequency: Frequency.annual,
          ),
        ],
        revenues: [revenue(amount: 2000, startDate: monthsAgo(11))],
        range: StatsRange.sixMonths,
      );

      expect(state.annualRecurringExpenses, 300);
      expect(state.annualRecurringIncomes, 24000);
    });
  });

  group('slices', () {
    test('covers the current month only', () async {
      final state = await readState(
        expenses: [
          expense(
            amount: 300,
            startDate: monthsAgo(5),
            categorySlug: 'alimentation.courses',
          ),
          expense(
            amount: 600,
            startDate: monthsAgo(2),
            frequency: Frequency.oneTime,
            categorySlug: 'transport.essence',
          ),
        ],
      );

      final food = state.slices.single;
      expect(food.groupKey, 'alimentation');
      expect(food.amount, 300);
      expect(food.share, closeTo(1, 0.001));
    });

    test('shares the month between its groups', () async {
      final state = await readState(
        expenses: [
          expense(
            amount: 300,
            startDate: monthsAgo(5),
            categorySlug: 'alimentation.courses',
          ),
          expense(
            amount: 100,
            startDate: monthsAgo(5),
            categorySlug: 'transport.essence',
          ),
        ],
      );

      expect(state.slices.first.groupKey, 'alimentation');
      expect(state.slices.first.share, closeTo(0.75, 0.001));
      expect(
        state.slices.fold<double>(0, (sum, slice) => sum + slice.share),
        closeTo(1.0, 0.001),
      );
    });

    test('gives uncategorised expenses their own bucket', () async {
      final state = await readState(
        expenses: [expense(amount: 100, startDate: monthsAgo(5))],
      );

      final bucket = state.slices.single;
      expect(bucket.groupKey, CategoryDisplayResolver.uncategorizedKey);
      expect(bucket.label, 'Non catégorisé');
    });

    test('drops a category that no longer costs anything', () async {
      final state = await readState(
        expenses: [
          expense(
            amount: 100,
            startDate: monthsAgo(11),
            categorySlug: 'alimentation.courses',
          ),
          expense(
            amount: 300,
            startDate: monthsAgo(11),
            categorySlug: 'loisirs.sorties',
          )..endDate = DateTime(thisMonth.year, thisMonth.month - 6, 28),
        ],
      );

      expect(state.slices.map((slice) => slice.groupKey), ['alimentation']);
    });

    test('is empty when nothing was spent', () async {
      final state = await readState();

      expect(state.slices, isEmpty);
    });
  });

  group('movers', () {
    test('ranks categories by how much they moved', () async {
      final state = await readState(
        expenses: [
          expense(
            amount: 200,
            startDate: monthsAgo(2),
            categorySlug: 'loisirs.sorties',
          ),
          expense(
            amount: 50,
            startDate: monthsAgo(11),
            categorySlug: 'alimentation.courses',
          ),
        ],
      );

      expect(state.movers.first.groupKey, 'loisirs');
      expect(state.movers.first.isNew, isTrue);
      expect(
        state.movers.map((trend) => trend.groupKey),
        isNot(contains('alimentation')),
      );
    });

    test('surfaces a category that stopped costing anything', () async {
      final state = await readState(
        expenses: [
          expense(
            amount: 100,
            startDate: monthsAgo(11),
            categorySlug: 'alimentation.courses',
          ),
          expense(
            amount: 300,
            startDate: monthsAgo(11),
            categorySlug: 'loisirs.sorties',
          )..endDate = DateTime(thisMonth.year, thisMonth.month - 6, 28),
        ],
      );

      final leisure = state.movers.firstWhere(
        (trend) => trend.groupKey == 'loisirs',
      );
      expect(leisure.amount, 0);
      expect(leisure.delta, -1800);
      expect(state.movers.first.groupKey, 'loisirs');
    });

    test('stays silent when nothing precedes the range', () async {
      final state = await readState(
        expenses: [
          expense(
            amount: 200,
            startDate: monthsAgo(3),
            categorySlug: 'alimentation.courses',
          ),
        ],
      );

      expect(state.hasExpenseComparison, isFalse);
      expect(state.movers, isEmpty);
    });
  });

  group('quiet months', () {
    test('leaves the months before the first move out of the chart', () async {
      final state = await readState(
        expenses: [
          expense(
            amount: 100,
            startDate: monthsAgo(1),
            frequency: Frequency.oneTime,
          ),
        ],
      );

      expect(state.flows.map((flow) => flow.month), [
        DateTime(thisMonth.year, thisMonth.month - 1),
        thisMonth,
      ]);
    });

    test('averages over the months that carry data only', () async {
      final state = await readState(
        revenues: [
          revenue(
            amount: 600,
            startDate: monthsAgo(1),
            frequency: Frequency.oneTime,
          ),
        ],
        expenses: [
          expense(
            amount: 100,
            startDate: monthsAgo(1),
            frequency: Frequency.oneTime,
          ),
        ],
      );

      expect(state.coveredMonths, 1);
      expect(state.averageNet, 500);
    });

    test('holds a quiet month between two moves against the average', () async {
      final state = await readState(
        expenses: [
          expense(
            amount: 100,
            startDate: monthsAgo(2),
            frequency: Frequency.oneTime,
          ),
          expense(
            amount: 200,
            startDate: thisMonth,
            frequency: Frequency.oneTime,
          ),
        ],
      );

      expect(state.flows, hasLength(3));
      expect(state.coveredMonths, 2);
      expect(state.averageNet, -150);
    });
  });

  group('history depth', () {
    test('flags a budget too young to compare', () async {
      final state = await readState(
        expenses: [expense(amount: 100, startDate: monthsAgo(1))],
      );

      expect(state.trackedMonths, 2);
      expect(state.hasHistory, isFalse);
      expect(state.monthsUntilHistory, 1);
    });

    test('opens up once three months are tracked', () async {
      final state = await readState(
        expenses: [expense(amount: 100, startDate: monthsAgo(2))],
      );

      expect(state.trackedMonths, 3);
      expect(state.hasHistory, isTrue);
    });
  });
}
