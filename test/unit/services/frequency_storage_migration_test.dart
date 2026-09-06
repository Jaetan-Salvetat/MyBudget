import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/repositories/recurring_transaction_repository.dart';
import 'package:mybudget/core/services/data/frequency_storage_migration.dart';
import 'package:mybudget/models/expense_model.dart';

class _FakeRepository implements RecurringTransactionRepository<ExpenseModel> {
  _FakeRepository(this.rows);

  final List<ExpenseModel> rows;
  int updates = 0;

  @override
  List<ExpenseModel> getAll() => rows;

  @override
  int update(ExpenseModel entity) {
    updates++;
    return entity.id;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} hors périmètre');
}

ExpenseModel _expenseStoring(String frequency) => ExpenseModel()
  ..id = 1
  ..name = 'Loyer'
  ..amount = 800
  ..startDate = DateTime(2026)
  ..accountId = 1
  ..frequency = frequency;

void main() {
  test('réécrit un libellé français en clé de stockage', () {
    final row = _expenseStoring('Annuel');
    final repository = _FakeRepository([row]);

    expect(FrequencyStorageMigration.run(repository), 1);
    expect(row.frequency, Frequency.annual.storageKey);
    expect(repository.updates, 1);
  });

  test('ne touche pas une ligne déjà canonique', () {
    final row = _expenseStoring(Frequency.monthly.storageKey);
    final repository = _FakeRepository([row]);

    expect(FrequencyStorageMigration.run(repository), 0);
    expect(repository.updates, 0);
  });

  test('normalise une valeur illisible sur mensuel', () {
    final row = _expenseStoring('hebdomadaire');
    final repository = _FakeRepository([row]);

    expect(FrequencyStorageMigration.run(repository), 1);
    expect(row.frequency, Frequency.monthly.storageKey);
  });

  test('est idempotente', () {
    final repository = _FakeRepository([_expenseStoring('Ponctuel')]);

    expect(FrequencyStorageMigration.run(repository), 1);
    expect(FrequencyStorageMigration.run(repository), 0);
  });
}
