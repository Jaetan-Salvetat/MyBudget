import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/loan_event_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';
import 'package:mybudget/ui/stats/stats_screen.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockLoanRepository extends Mock implements LoanRepository {}

class MockLoanEventRepository extends Mock implements LoanEventRepository {}

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('fr_FR');
  });

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
    when(() => mockRevenueRepo.getAll()).thenReturn([]);
    when(() => mockRevenueRepo.getActive()).thenReturn([]);
    when(() => mockRevenueRepo.getClosed()).thenReturn([]);
    when(() => mockExpenseRepo.getClosed()).thenReturn([]);
    when(() => mockLoanRepo.getAll()).thenReturn([]);
    when(() => mockLoanEventRepo.getAll()).thenReturn([]);
    when(() => mockCategoryOverrideRepo.getAll()).thenReturn({});
  });

  ExpenseModel expense({
    required double amount,
    required DateTime startDate,
    required String categorySlug,
  }) => ExpenseModel.create(
    name: 'Dépense',
    amount: amount,
    accountId: 1,
    startDate: startDate,
    frequency: Frequency.monthly,
    categorySlug: categorySlug,
  );

  Future<void> pumpScreen(
    WidgetTester tester,
    List<ExpenseModel> expenses,
  ) async {
    when(() => mockExpenseRepo.getAll()).thenReturn([...expenses]);
    when(() => mockExpenseRepo.getActive()).thenReturn([...expenses]);

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

    await tester.runAsync(() async {
      await container.read(expenseProvider.future);
      await container.read(revenueProvider.future);
      await container.read(loanProvider.future);
      await container.read(categoryDisplayResolverProvider.future);
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: FrostedTheme.light(seedColor: const Color(0xFF2A55D3)),
          home: const Scaffold(body: StatsScreen(isNested: true)),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  double topOf(WidgetTester tester, String label) =>
      tester.getTopLeft(find.text(label)).dy;

  testWidgets('keeps the movers above the breakdown when something moved', (
    tester,
  ) async {
    await pumpScreen(tester, [
      expense(
        amount: 100,
        startDate: monthsAgo(11),
        categorySlug: 'alimentation.courses',
      ),
      expense(
        amount: 300,
        startDate: monthsAgo(4),
        categorySlug: 'loisirs.sorties',
      ),
    ]);

    expect(
      topOf(tester, 'CE QUI A BOUGÉ'),
      lessThan(topOf(tester, 'RÉPARTITION')),
    );
  });

  testWidgets('drops the movers below the breakdown when it has nothing', (
    tester,
  ) async {
    await pumpScreen(tester, [
      expense(
        amount: 100,
        startDate: monthsAgo(3),
        categorySlug: 'alimentation.courses',
      ),
    ]);

    expect(
      topOf(tester, 'CE QUI A BOUGÉ'),
      greaterThan(topOf(tester, 'RÉPARTITION')),
    );
  });
}
