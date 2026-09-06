import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_change.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/data/model/expense_model.dart';
import 'package:mybudget/data/model/transaction_event_model.dart';
import 'package:mybudget/data/provider/expenses_provider.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/data/repository/expense_repository.dart';
import 'package:mybudget/data/repository/transaction_event_repository.dart';
import 'package:mybudget/ui/shared/expense_queries.dart';

class InMemoryExpenseRepository implements ExpenseRepository {
  final List<ExpenseModel> rows = [];
  int _nextId = 1;

  @override
  List<ExpenseModel> getAll() => [...rows];

  @override
  ExpenseModel? get(int id) => rows.where((row) => row.id == id).firstOrNull;

  @override
  List<ExpenseModel> getActive() =>
      rows.where((row) => row.endDate == null).toList();

  @override
  List<ExpenseModel> getClosed() =>
      rows.where((row) => row.endDate != null).toList();

  @override
  List<ExpenseModel> getChain(int rootId) =>
      rows.where((row) => row.id == rootId || row.parentId == rootId).toList();

  @override
  int add(ExpenseModel expense) {
    if (expense.id == 0) expense.id = _nextId++;
    rows.add(expense);
    return expense.id;
  }

  @override
  int update(ExpenseModel expense) {
    rows.removeWhere((row) => row.id == expense.id);
    rows.add(expense);
    return expense.id;
  }

  @override
  bool delete(int id) {
    final before = rows.length;
    rows.removeWhere((row) => row.id == id);
    return rows.length != before;
  }

  @override
  void deleteAll() => rows.clear();
}

class InMemoryTransactionEventRepository implements TransactionEventRepository {
  final List<TransactionEventModel> rows = [];

  @override
  List<TransactionEventModel> getForRoot(int rootId, TransactionType type) =>
      rows
          .where((row) => row.rootId == rootId && row.typeEnum == type)
          .toList();

  @override
  void add(TransactionEventModel event) => rows.add(event);

  @override
  void deleteForRoot(int rootId, TransactionType type) =>
      rows.removeWhere((row) => row.rootId == rootId && row.typeEnum == type);

  @override
  void deleteAll() => rows.clear();
}

void main() {
  late InMemoryExpenseRepository expenses;
  late InMemoryTransactionEventRepository events;

  setUp(() {
    expenses = InMemoryExpenseRepository();
    events = InMemoryTransactionEventRepository();
  });

  ProviderContainer containerWith() {
    final container = ProviderContainer(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(expenses),
        transactionEventRepositoryProvider.overrideWithValue(events),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  ExpenseModel rent() {
    final expense = ExpenseModel.create(
      name: 'Loyer',
      amount: 800,
      categorySlug: 'logement.loyer',
      startDate: DateTime(DateTime.now().year, DateTime.now().month - 2, 1),
      frequency: Frequency.monthly,
      accountId: 1,
    );
    expenses.add(expense);
    return expense;
  }

  test('a refiling reaches the timeline of the rule it was made on', () async {
    final expense = rent();
    final container = containerWith();
    await container.read(expenseProvider.future);

    await container
        .read(expenseProvider.notifier)
        .updateExpense(expense.copyWith(categorySlug: 'logement.charges'));

    final recorded = container.read(expenseEventsProvider(expense.id));
    expect(recorded, hasLength(1));
    expect(recorded.single.changeEnum, TransactionChange.category);
    expect(recorded.single.previousValue, 'logement.loyer');
    expect(recorded.single.nextValue, 'logement.charges');
  });

  test('a refiling made after a revision stays on the same root', () async {
    final expense = rent();
    final container = containerWith();
    await container.read(expenseProvider.future);
    final notifier = container.read(expenseProvider.notifier);

    await notifier.updateExpense(expense.copyWith(amount: 900));
    final live = expenses.getActive().single;
    expect(live.parentId, expense.id);

    await notifier.updateExpense(
      live.copyWith(categorySlug: 'logement.charges'),
    );

    expect(container.read(expenseEventsProvider(expense.id)), hasLength(1));
  });

  test('the timeline is emptied with the rule it belonged to', () async {
    final expense = rent();
    final container = containerWith();
    await container.read(expenseProvider.future);
    final notifier = container.read(expenseProvider.notifier);

    await notifier.updateExpense(
      expense.copyWith(categorySlug: 'logement.charges'),
    );
    await notifier.deletePermanently(expense.id);

    expect(container.read(expenseEventsProvider(expense.id)), isEmpty);
  });

  test('a timeline already read refreshes on the next refiling', () async {
    final expense = rent();
    final container = containerWith();
    await container.read(expenseProvider.future);

    final subscription = container.listen(
      expenseEventsProvider(expense.id),
      (_, _) {},
    );
    addTearDown(subscription.close);
    expect(subscription.read(), isEmpty);

    await container
        .read(expenseProvider.notifier)
        .updateExpense(expense.copyWith(categorySlug: 'logement.charges'));

    expect(subscription.read(), hasLength(1));
  });
}
