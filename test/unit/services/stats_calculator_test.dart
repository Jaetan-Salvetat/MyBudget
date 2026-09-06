import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/entities/loan.dart';
import 'package:mybudget/core/entities/loan_installment.dart';
import 'package:mybudget/core/entities/loan_schedule.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/services/stats_calculator.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/models/revenue_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CategoryTaxonomyService taxonomy;

  setUpAll(() async {
    taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
  });

  ExpenseModel expense({
    required double amount,
    required DateTime startDate,
    String frequency = 'Mensuel',
    String? categorySlug,
    DateTime? endDate,
  }) {
    final model = ExpenseModel.create(
      name: 'Dépense',
      amount: amount,
      accountId: 1,
      startDate: startDate,
      frequency: frequency,
      categorySlug: categorySlug,
    );
    return endDate == null ? model : model.copyWith(endDate: endDate);
  }

  RevenueModel revenue({
    required double amount,
    required DateTime startDate,
    String frequency = 'Mensuel',
  }) {
    return RevenueModel.create(
      name: 'Revenu',
      amount: amount,
      accountId: 1,
      startDate: startDate,
      frequency: frequency,
    );
  }

  Loan loanPaying(double payment, List<DateTime> dates) {
    final schedule = LoanSchedule(
      borrowedAmount: 10000,
      installments: [
        for (var index = 0; index < dates.length; index++)
          LoanInstallment(
            number: index + 1,
            date: dates[index],
            openingCapital: 10000,
            interest: 0,
            insurance: 0,
            principal: payment,
            closingCapital: 10000 - payment * (index + 1),
            kind: LoanInstallmentKind.amortizing,
          ),
      ],
    );

    return Loan(
      model: LoanModel(
        name: 'Prêt',
        amount: 10000,
        lenderName: 'Banque',
        accountId: 1,
        startDate: dates.first,
        endDate: dates.last,
        interestRate: 0,
        duration: dates.length,
        dayOfMonth: dates.first.day,
      ),
      schedule: schedule,
      contractualSchedule: schedule,
      events: const [],
      annualPercentageRate: 0,
      asOf: dates.last,
    );
  }

  StatsCalculator calculatorWith({
    List<ExpenseModel> expenses = const [],
    List<RevenueModel> revenues = const [],
    List<Loan> loans = const [],
  }) {
    return StatsCalculator(
      expenses: expenses,
      revenues: revenues,
      loans: loans,
      resolver: CategoryDisplayResolver(
        taxonomy: taxonomy,
        overrides: const {},
      ),
    );
  }

  group('monthsEndingAt', () {
    test('returns the requested count, oldest first, ending on the anchor', () {
      final months = StatsCalculator.monthsEndingAt(DateTime(2026, 3), 4);

      expect(months, [
        DateTime(2025, 12),
        DateTime(2026, 1),
        DateTime(2026, 2),
        DateTime(2026, 3),
      ]);
    });

    test('crosses the year boundary backwards', () {
      final months = StatsCalculator.monthsEndingAt(DateTime(2026), 2);

      expect(months, [DateTime(2025, 12), DateTime(2026)]);
    });
  });

  group('flowsOver', () {
    test('spreads a monthly expense across every month of the window', () {
      final calculator = calculatorWith(
        expenses: [expense(amount: 100, startDate: DateTime(2026, 1, 5))],
        revenues: [revenue(amount: 900, startDate: DateTime(2026, 1, 2))],
      );

      final flows = calculator.flowsOver(
        StatsCalculator.monthsEndingAt(DateTime(2026, 3), 3),
      );

      expect(flows.map((flow) => flow.expenses), [100, 100, 100]);
      expect(flows.map((flow) => flow.incomes), [900, 900, 900]);
      expect(flows.first.net, 800);
    });

    test('keeps a one-time expense in its own month', () {
      final calculator = calculatorWith(
        expenses: [
          expense(
            amount: 250,
            startDate: DateTime(2026, 2, 14),
            frequency: 'Ponctuel',
          ),
        ],
      );

      final flows = calculator.flowsOver(
        StatsCalculator.monthsEndingAt(DateTime(2026, 3), 3),
      );

      expect(flows.map((flow) => flow.expenses), [0, 250, 0]);
    });

    test('counts a loan instalment in the month it falls', () {
      final calculator = calculatorWith(
        loans: [
          loanPaying(180, [
            DateTime(2026, 1, 10),
            DateTime(2026, 2, 10),
            DateTime(2026, 3, 10),
          ]),
        ],
      );

      final flows = calculator.flowsOver(
        StatsCalculator.monthsEndingAt(DateTime(2026, 3), 4),
      );

      expect(flows.map((flow) => flow.expenses), [0, 180, 180, 180]);
    });

    test('stops a closed expense after its end date', () {
      final calculator = calculatorWith(
        expenses: [
          expense(
            amount: 60,
            startDate: DateTime(2026, 1, 3),
            endDate: DateTime(2026, 2, 3),
          ),
        ],
      );

      final flows = calculator.flowsOver(
        StatsCalculator.monthsEndingAt(DateTime(2026, 4), 4),
      );

      expect(flows.map((flow) => flow.expenses), [60, 60, 0, 0]);
    });
  });

  group('activeMonthsOver', () {
    test('counts only the months where something moved', () {
      final calculator = calculatorWith(
        expenses: [
          expense(
            amount: 100,
            startDate: DateTime(2026, 2, 5),
            frequency: 'Ponctuel',
          ),
          expense(
            amount: 40,
            startDate: DateTime(2026, 4, 5),
            frequency: 'Ponctuel',
          ),
        ],
      );

      final months = StatsCalculator.monthsEndingAt(DateTime(2026, 4), 4);

      expect(calculator.activeMonthsOver(months), 2);
    });

    test('counts a recurring expense in every month it lands on', () {
      final calculator = calculatorWith(
        expenses: [expense(amount: 100, startDate: DateTime(2026, 2, 5))],
      );

      final months = StatsCalculator.monthsEndingAt(DateTime(2026, 4), 4);

      expect(calculator.activeMonthsOver(months), 3);
    });

    test('is zero when nothing happened over the window', () {
      final calculator = calculatorWith();
      final months = StatsCalculator.monthsEndingAt(DateTime(2026, 4), 4);

      expect(calculator.activeMonthsOver(months), 0);
    });
  });

  group('expensesByGroupOver', () {
    test('sums a group over every month of the window', () {
      final calculator = calculatorWith(
        expenses: [
          expense(
            amount: 40,
            startDate: DateTime(2026, 1, 5),
            categorySlug: 'alimentation.courses',
          ),
          expense(
            amount: 25,
            startDate: DateTime(2026, 1, 5),
            categorySlug: 'transport.essence',
          ),
        ],
      );

      final totals = calculator.expensesByGroupOver(
        StatsCalculator.monthsEndingAt(DateTime(2026, 3), 3),
      );

      expect(totals['alimentation'], 120);
      expect(totals['transport'], 75);
    });

    test('books loan instalments under the finance group', () {
      final calculator = calculatorWith(
        loans: [
          loanPaying(200, [DateTime(2026, 2, 10), DateTime(2026, 3, 10)]),
        ],
      );

      final totals = calculator.expensesByGroupOver(
        StatsCalculator.monthsEndingAt(DateTime(2026, 3), 3),
      );

      expect(totals[StatsCalculator.loanGroupKey], 400);
    });

    test('sums to the same total as the flows', () {
      final months = StatsCalculator.monthsEndingAt(DateTime(2026, 3), 3);
      final calculator = calculatorWith(
        expenses: [
          expense(
            amount: 40,
            startDate: DateTime(2026, 1, 5),
            categorySlug: 'alimentation.courses',
          ),
          expense(amount: 10, startDate: DateTime(2026, 1, 5)),
        ],
        loans: [
          loanPaying(200, [DateTime(2026, 2, 10)]),
        ],
      );

      final totals = calculator.expensesByGroupOver(months);
      final flowed = calculator
          .flowsOver(months)
          .fold<double>(0, (sum, flow) => sum + flow.expenses);

      expect(
        totals.values.fold<double>(0, (sum, value) => sum + value),
        flowed,
      );
    });
  });

  group('recurringExpensesOver', () {
    test('counts recurring expenses and loan instalments only', () {
      final months = StatsCalculator.monthsEndingAt(DateTime(2026, 3), 3);
      final calculator = calculatorWith(
        expenses: [
          expense(amount: 30, startDate: DateTime(2026, 1, 5)),
          expense(
            amount: 500,
            startDate: DateTime(2026, 2, 8),
            frequency: 'Ponctuel',
          ),
        ],
        loans: [
          loanPaying(120, [DateTime(2026, 3, 10)]),
        ],
      );

      expect(calculator.recurringExpensesOver(months), 210);
    });

    test('counts an annual expense on its anniversary month', () {
      final calculator = calculatorWith(
        expenses: [
          expense(
            amount: 300,
            startDate: DateTime(2025, 2, 20),
            frequency: 'Annuel',
          ),
        ],
      );

      final months = StatsCalculator.monthsEndingAt(DateTime(2026, 3), 3);

      expect(calculator.recurringExpensesOver(months), 300);
    });
  });
}
