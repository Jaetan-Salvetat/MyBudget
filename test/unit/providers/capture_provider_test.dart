import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/loan_event_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/capture/capture_provider.dart';
import 'package:mybudget/ui/capture/models/journal_bucket.dart';
import 'package:mybudget/ui/capture/models/journal_entry.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockLoanRepository extends Mock implements LoanRepository {}

class MockLoanEventRepository extends Mock implements LoanEventRepository {}

ExpenseModel expenseOf({
  required int id,
  required String name,
  required double amount,
  required DateTime startDate,
  String frequency = 'Ponctuel',
  String? categorySlug,
}) {
  final expense = ExpenseModel.create(
    name: name,
    amount: amount,
    startDate: startDate,
    frequency: frequency,
    accountId: 1,
    categorySlug: categorySlug,
  );
  expense.id = id;
  return expense;
}

RevenueModel revenueOf({
  required int id,
  required String name,
  required double amount,
  required DateTime startDate,
  String frequency = 'Ponctuel',
}) {
  final revenue = RevenueModel.create(
    name: name,
    amount: amount,
    startDate: startDate,
    frequency: frequency,
    accountId: 1,
  );
  revenue.id = id;
  return revenue;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAccountRepository accounts;
  late MockExpenseRepository expenses;
  late MockRevenueRepository revenues;
  late MockLoanRepository loans;
  late MockLoanEventRepository loanEvents;

  setUp(() {
    accounts = MockAccountRepository();
    expenses = MockExpenseRepository();
    revenues = MockRevenueRepository();
    loans = MockLoanRepository();
    loanEvents = MockLoanEventRepository();

    when(() => accounts.getAll()).thenReturn([]);
    when(() => expenses.getAll()).thenReturn([]);
    when(() => expenses.getActive()).thenReturn([]);
    when(() => revenues.getAll()).thenReturn([]);
    when(() => revenues.getActive()).thenReturn([]);
    when(() => loans.getAll()).thenReturn([]);
    when(() => loanEvents.getAll()).thenReturn([]);
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(accounts),
        expenseRepositoryProvider.overrideWithValue(expenses),
        revenueRepositoryProvider.overrideWithValue(revenues),
        loanRepositoryProvider.overrideWithValue(loans),
        loanEventRepositoryProvider.overrideWithValue(loanEvents),
      ],
    );
  }

  Future<ProviderContainer> containerReady() async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(expenseProvider.future);
    await container.read(revenueProvider.future);
    await container.read(loanProvider.future);
    return container;
  }

  group('todayJournal', () {
    test('keeps only what is dated today', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 12, 4);
      final yesterday = today.subtract(const Duration(days: 1));

      when(() => expenses.getActive()).thenReturn([
        expenseOf(id: 1, name: 'Carrefour', amount: 42.30, startDate: today),
        expenseOf(
          id: 2,
          name: 'Decathlon',
          amount: 89.90,
          startDate: yesterday,
        ),
      ]);

      final container = await containerReady();
      final journal = container.read(todayJournalProvider);

      expect(journal.map((e) => e.name), ['Carrefour']);
    });

    test('reads newest first, so what just landed opens the list', () async {
      final now = DateTime.now();
      final morning = DateTime(now.year, now.month, now.day, 8, 12);
      final noon = DateTime(now.year, now.month, now.day, 12, 4);

      when(() => expenses.getActive()).thenReturn([
        expenseOf(id: 1, name: 'Carrefour', amount: 42.30, startDate: noon),
        expenseOf(id: 2, name: 'Café', amount: 4, startDate: morning),
      ]);

      final container = await containerReady();

      expect(
        container.read(todayJournalProvider).map((e) => e.name),
        ['Carrefour', 'Café'],
      );
    });

    test('holds revenues next to expenses', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 9, 0);

      when(() => expenses.getActive()).thenReturn([
        expenseOf(id: 1, name: 'Carrefour', amount: 42.30, startDate: today),
      ]);
      when(() => revenues.getActive()).thenReturn([
        revenueOf(
          id: 1,
          name: 'Remboursement',
          amount: 20,
          startDate: today.add(const Duration(hours: 1)),
        ),
      ]);

      final container = await containerReady();
      final journal = container.read(todayJournalProvider);

      expect(journal.length, 2);
      expect(journal.first.type, TransactionType.income);
    });

    test('a recurring expense keeps its hour on today\'s date', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 7, 30);

      when(() => expenses.getActive()).thenReturn([
        expenseOf(
          id: 1,
          name: 'Netflix',
          amount: 13.99,
          startDate: today,
          frequency: 'Mensuel',
        ),
      ]);

      final container = await containerReady();
      final entry = container.read(todayJournalProvider).single;

      expect(entry.at.day, now.day);
      expect(entry.at.hour, 7);
      expect(entry.hasTime, isTrue);
    });

    test('an entry filled from a form has no hour to show', () async {
      final now = DateTime.now();

      when(() => expenses.getActive()).thenReturn([
        expenseOf(
          id: 1,
          name: 'Assurance',
          amount: 32,
          startDate: DateTime(now.year, now.month, now.day),
        ),
      ]);

      final container = await containerReady();

      expect(container.read(todayJournalProvider).single.hasTime, isFalse);
    });
  });

  group('the slice total', () {
    test('counts expenses up and revenues down', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 10, 0);

      when(() => expenses.getActive()).thenReturn([
        expenseOf(id: 1, name: 'Carrefour', amount: 42.30, startDate: today),
        expenseOf(id: 2, name: 'Café', amount: 4, startDate: today),
      ]);
      when(() => revenues.getActive()).thenReturn([
        revenueOf(id: 1, name: 'Remboursement', amount: 20, startDate: today),
      ]);

      final container = await containerReady();

      expect(
        container.read(journalBucketsProvider).first.spent,
        closeTo(26.30, 0.001),
      );
    });
  });

  group('journalBuckets', () {
    test('reads the past backwards, newest slice first', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 10, 0);
      final earlier = DateTime(now.year, now.month, 1, 9, 0);

      when(() => expenses.getActive()).thenReturn([
        expenseOf(id: 1, name: 'Loyer', amount: 800, startDate: earlier),
        expenseOf(id: 2, name: 'Carrefour', amount: 42.30, startDate: today),
      ]);

      final container = await containerReady();
      final buckets = container.read(journalBucketsProvider);

      expect(buckets.first.kind, JournalBucketKind.today);
      expect(buckets.first.entries.single.name, 'Carrefour');
      expect(
        buckets.expand((bucket) => bucket.entries).map((e) => e.name),
        containsAll(['Carrefour', 'Loyer']),
      );
    });

    test('leaves out the slices that recorded nothing', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 10, 0);

      when(() => expenses.getActive()).thenReturn([
        expenseOf(id: 1, name: 'Carrefour', amount: 42.30, startDate: today),
      ]);

      final container = await containerReady();

      expect(container.read(journalBucketsProvider).length, 1);
    });

    test('a slice reads newest line first', () async {
      final now = DateTime.now();

      when(() => expenses.getActive()).thenReturn([
        expenseOf(
          id: 1,
          name: 'Café',
          amount: 4,
          startDate: DateTime(now.year, now.month, now.day, 8, 12),
        ),
        expenseOf(
          id: 2,
          name: 'Carrefour',
          amount: 42.30,
          startDate: DateTime(now.year, now.month, now.day, 12, 4),
        ),
      ]);

      final container = await containerReady();

      expect(
        container.read(journalBucketsProvider).first.entries.map((e) => e.name),
        ['Carrefour', 'Café'],
      );
    });

    test('a monthly expense lands in every month since its first', () async {
      final now = DateTime.now();
      final twoMonthsAgo = DateTime(now.year, now.month - 2, 3, 9, 0);

      when(() => expenses.getActive()).thenReturn([
        expenseOf(
          id: 1,
          name: 'Netflix',
          amount: 13.99,
          startDate: twoMonthsAgo,
          frequency: 'Mensuel',
        ),
      ]);

      final container = await containerReady();
      final landings = container
          .read(journalBucketsProvider)
          .expand((bucket) => bucket.entries)
          .toList();

      expect(landings.length, 3);
      expect(
        landings.map((entry) => entry.at.month).toSet().length,
        3,
      );
    });

    test('a yearly expense comes back a year on, same month', () async {
      final now = DateTime.now();
      final lastYear = DateTime(now.year - 1, now.month, 12, 9, 0);

      when(() => expenses.getActive()).thenReturn([
        expenseOf(
          id: 1,
          name: 'Assurance habitation',
          amount: 214,
          startDate: lastYear,
          frequency: 'Annuel',
        ),
      ]);

      final container = await containerReady();
      final landings = container
          .read(journalBucketsProvider)
          .expand((bucket) => bucket.entries)
          .toList();

      expect(landings.length, 2);
      expect(
        landings.map((entry) => entry.at.year).toSet(),
        {now.year - 1, now.year},
      );
    });

    test('never reaches past today', () async {
      final now = DateTime.now();
      final tomorrow = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(const Duration(days: 1));

      when(() => expenses.getActive()).thenReturn([
        expenseOf(id: 1, name: 'Plus tard', amount: 12, startDate: tomorrow),
      ]);

      final container = await containerReady();

      expect(container.read(journalBucketsProvider), isEmpty);
    });
  });

  group('loans', () {
    LoanModel loanOf({required DateTime startDate, required int dayOfMonth}) {
      return LoanModel(
        id: 7,
        name: 'Prêt auto',
        amount: 5000,
        duration: 12,
        interestRate: 5,
        accountId: 1,
        startDate: startDate,
        endDate: DateTime(startDate.year + 1, startDate.month, dayOfMonth),
        dayOfMonth: dayOfMonth,
        lenderName: 'Banque',
      );
    }

    test('every instalment already due lands in the journal', () async {
      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);

      when(
        () => loans.getAll(),
      ).thenReturn([loanOf(startDate: threeMonthsAgo, dayOfMonth: 1)]);

      final container = await containerReady();
      final landings = container
          .read(journalBucketsProvider)
          .expand((bucket) => bucket.entries)
          .where((entry) => entry.source == JournalEntrySource.loan)
          .toList();

      expect(landings, isNotEmpty);
      expect(landings.every((entry) => !entry.at.isAfter(now)), isTrue);
      expect(landings.first.name, 'Prêt auto');
    });

    test('an instalment reads as a credit repayment', () async {
      final now = DateTime.now();

      when(() => loans.getAll()).thenReturn([
        loanOf(startDate: DateTime(now.year, now.month - 2, 1), dayOfMonth: 1),
      ]);

      final container = await containerReady();
      final instalment = container
          .read(journalBucketsProvider)
          .expand((bucket) => bucket.entries)
          .firstWhere((entry) => entry.source == JournalEntrySource.loan);

      expect(instalment.categorySlug, kLoanCategorySlug);
      expect(instalment.type, TransactionType.expense);
      expect(instalment.amount, greaterThan(0));
    });

    test('an instalment answers to no quick-add submission', () async {
      final now = DateTime.now();

      when(() => loans.getAll()).thenReturn([
        loanOf(startDate: DateTime(now.year, now.month - 1, 1), dayOfMonth: 1),
      ]);

      final container = await containerReady();
      final instalment = container
          .read(journalBucketsProvider)
          .expand((bucket) => bucket.entries)
          .firstWhere((entry) => entry.source == JournalEntrySource.loan);

      expect(
        instalment.sameTransaction(TransactionType.expense, instalment.id),
        isFalse,
      );
    });
  });

  group('remainingThisMonth', () {
    test('takes revenues minus expenses and loan payments', () async {
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);

      when(() => expenses.getActive()).thenReturn([
        expenseOf(
          id: 1,
          name: 'Loyer',
          amount: 800,
          startDate: thisMonth,
          frequency: 'Mensuel',
        ),
      ]);
      when(() => revenues.getActive()).thenReturn([
        revenueOf(
          id: 1,
          name: 'Salaire',
          amount: 2480,
          startDate: thisMonth,
          frequency: 'Mensuel',
        ),
      ]);

      final container = await containerReady();

      expect(container.read(remainingThisMonthProvider), closeTo(1680, 0.001));
    });
  });
}
