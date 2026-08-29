import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/utils/history_utils.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class FakeExpenseModel extends Fake implements ExpenseModel {}

/// Closing a rule says when it stopped, not what it last paid : a rule
/// deleted today ran until today, and one whose day never came round never
/// ran at all.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => registerFallbackValue(FakeExpenseModel()));

  late MockExpenseRepository repo;
  late ExpenseModel? closed;
  late List<int> deleted;

  final today = dayOnly(DateTime.now());

  ExpenseModel subscription({
    required DateTime startDate,
    String frequency = 'Mensuel',
  }) {
    final expense = ExpenseModel.create(
      name: 'VPS',
      amount: 20,
      startDate: startDate,
      frequency: frequency,
      accountId: 1,
    );
    expense.id = 7;
    return expense;
  }

  setUp(() {
    repo = MockExpenseRepository();
    closed = null;
    deleted = [];

    when(() => repo.getActive()).thenReturn([]);
    when(() => repo.getClosed()).thenReturn([]);
    when(() => repo.update(any())).thenAnswer((invocation) {
      closed = invocation.positionalArguments.first as ExpenseModel;
      return 7;
    });
    when(() => repo.delete(any())).thenAnswer((invocation) {
      deleted.add(invocation.positionalArguments.first as int);
      return true;
    });
    when(() => repo.add(any())).thenReturn(8);
    when(() => repo.getChain(any())).thenReturn([]);
  });

  Future<ExpenseNotifier> notifierWith(ExpenseModel expense) async {
    when(() => repo.get(7)).thenReturn(expense);
    when(() => repo.getActive()).thenReturn([expense]);
    final container = ProviderContainer(
      overrides: [expenseRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await container.read(expenseProvider.future);
    return container.read(expenseProvider.notifier);
  }

  group('deleting a rule that has already run', () {
    test('closes it on the day it was deleted', () async {
      final expense = subscription(
        startDate: DateTime(today.year, today.month - 2, 1),
      );

      await (await notifierWith(expense)).deleteExpense(7);

      expect(dayOnly(closed!.endDate!), today);
      expect(deleted, isEmpty);
    });

    test('keeps it on the month it was deleted in', () async {
      final expense = subscription(
        startDate: DateTime(today.year, today.month - 2, 1),
      );

      await (await notifierWith(expense)).deleteExpense(7);

      expect(
        occursInMonth(
          closed!.startDate,
          closed!.endDate,
          closed!.frequencyEnum,
          DateTime(today.year, today.month),
        ),
        isTrue,
      );
    });

    test('drops it on the month after', () async {
      final expense = subscription(
        startDate: DateTime(today.year, today.month - 2, 1),
      );

      await (await notifierWith(expense)).deleteExpense(7);

      expect(
        occursInMonth(
          closed!.startDate,
          closed!.endDate,
          closed!.frequencyEnum,
          DateTime(today.year, today.month + 1),
        ),
        isFalse,
      );
    });
  });

  group('deleting a rule that never ran', () {
    test('a rule starting next month is removed for good', () async {
      final expense = subscription(
        startDate: today.add(const Duration(days: 10)),
      );

      await (await notifierWith(expense)).deleteExpense(7);

      expect(deleted, [7]);
      expect(closed, isNull);
    });

    test('a rule whose day has not come round yet is removed too', () async {
      final tomorrow = today.add(const Duration(days: 1));
      final expense = subscription(startDate: tomorrow);

      await (await notifierWith(expense)).deleteExpense(7);

      expect(deleted, [7]);
    });
  });

  group('a one-off', () {
    test('is removed for good, whenever it was', () async {
      final expense = subscription(
        startDate: today.subtract(const Duration(days: 3)),
        frequency: 'Ponctuel',
      );

      await (await notifierWith(expense)).deleteExpense(7);

      expect(deleted, [7]);
    });
  });

  group('editing a rule that has already run', () {
    test('closes the old row on the day of the edit', () async {
      final expense = subscription(
        startDate: DateTime(today.year, today.month - 2, 1),
      );
      final notifier = await notifierWith(expense);

      await notifier.updateExpense(expense.copyWith(amount: 35));

      expect(dayOnly(closed!.endDate!), today);
      expect(deleted, isEmpty);
    });
  });

  group('editing a rule that never ran', () {
    test('replaces it outright rather than leaving a dead row', () async {
      final expense = subscription(
        startDate: today.add(const Duration(days: 10)),
      );
      final notifier = await notifierWith(expense);

      await notifier.updateExpense(expense.copyWith(amount: 35));

      expect(deleted, [7]);
      expect(closed, isNull);
    });
  });

  group('correcting how a rule is described', () {
    late List<ExpenseModel> chain;
    late List<ExpenseModel> written;

    setUp(() {
      final august = subscription(
        startDate: DateTime(today.year, today.month - 2, 1),
      )..endDate = DateTime(today.year, today.month - 1, 1);
      final live = subscription(
        startDate: DateTime(today.year, today.month, 1),
      )..id = 9;
      chain = [august, live];
      written = [];

      when(() => repo.getChain(any())).thenReturn(chain);
      when(() => repo.update(any())).thenAnswer((invocation) {
        written.add(invocation.positionalArguments.first as ExpenseModel);
        return 7;
      });
    });

    test('a new category reaches every month the rule ever ran', () async {
      final expense = chain.first;
      final notifier = await notifierWith(expense);

      await notifier.updateExpense(
        expense.copyWith(categorySlug: 'finance.frais_bancaires'),
      );

      expect(written.length, 2);
      expect(
        written.every((e) => e.categorySlug == 'finance.frais_bancaires'),
        isTrue,
      );
      verifyNever(() => repo.add(any()));
    });

    test('a new beneficiary reaches the whole chain too', () async {
      final expense = chain.first;
      final notifier = await notifierWith(expense);

      await notifier.updateExpense(expense.copyWith(beneficiaryId: 4));

      expect(written.every((e) => e.beneficiaryId == 4), isTrue);
      verifyNever(() => repo.add(any()));
    });

    test('a new name still reaches the whole chain', () async {
      final expense = chain.first;
      final notifier = await notifierWith(expense);

      await notifier.updateExpense(expense.copyWith(name: 'Sumeria Pro'));

      expect(written.every((e) => e.name == 'Sumeria Pro'), isTrue);
      verifyNever(() => repo.add(any()));
    });
  });

  group('changing what a rule costs', () {
    test('a new amount opens a rule taking over', () async {
      final expense = subscription(
        startDate: DateTime(today.year, today.month - 2, 1),
      );
      final notifier = await notifierWith(expense);

      await notifier.updateExpense(expense.copyWith(amount: 35));

      verify(() => repo.add(any())).called(1);
    });

    test('a new account opens one too, so past months keep theirs', () async {
      final expense = subscription(
        startDate: DateTime(today.year, today.month - 2, 1),
      );
      final notifier = await notifierWith(expense);

      await notifier.updateExpense(expense.copyWith(accountId: 3));

      verify(() => repo.add(any())).called(1);
    });
  });

  group('whatever the edit or the delete', () {
    test('never writes an end that precedes the start', () async {
      for (final offset in [-60, -1, 0, 1, 10, 40]) {
        closed = null;
        final expense = subscription(
          startDate: today.add(Duration(days: offset)),
        );
        final notifier = await notifierWith(expense);

        await notifier.deleteExpense(7);
        if (closed != null) {
          expect(
            closed!.endDate!.isBefore(dayOnly(closed!.startDate)),
            isFalse,
            reason: 'delete at offset $offset',
          );
        }
      }
    });
  });
}
