import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/beneficiary_repository.dart';
import 'package:mybudget/core/repositories/category_memory_repository.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/loan_event_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/repositories/transaction_event_repository.dart';
import 'package:mybudget/core/repositories/transfer_repository.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/beneficiary_model.dart';
import 'package:mybudget/models/category_memory_model.dart';
import 'package:mybudget/models/category_override_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/loan_event_model.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/models/transaction_event_model.dart';
import 'package:mybudget/models/transfer_model.dart';
import 'package:objectbox/objectbox.dart';

class InMemoryTable<T> {
  InMemoryTable({
    required this._idOf,
    required this._assignId,
    required this._clone,
  });

  final int Function(T row) _idOf;
  final void Function(T row, int id) _assignId;
  final T Function(T row) _clone;

  final Map<int, T> _rows = <int, T>{};
  int _sequence = 0;

  List<T> get all => _rows.values.map(_clone).toList();

  int get count => _rows.length;

  T? get(int id) {
    final T? row = _rows[id];
    return row == null ? null : _clone(row);
  }

  int put(T row) {
    int id = _idOf(row);
    if (id == 0) {
      id = ++_sequence;
      _assignId(row, id);
    } else if (id > _sequence) {
      _sequence = id;
    }
    _rows[id] = _clone(row);
    return id;
  }

  bool remove(int id) => _rows.remove(id) != null;

  void removeMany(Iterable<int> ids) {
    for (final int id in ids.toList()) {
      _rows.remove(id);
    }
  }

  void removeAll() => _rows.clear();
}

class InMemoryAccountRepository implements AccountRepository {
  final InMemoryTable<AccountModel> table = InMemoryTable<AccountModel>(
    idOf: (AccountModel row) => row.id,
    assignId: (AccountModel row, int id) => row.id = id,
    clone: (AccountModel row) => row.copyWith(),
  );

  @override
  List<AccountModel> getAll() => table.all;

  @override
  int add(AccountModel account) => table.put(account);

  @override
  int update(AccountModel account) => table.put(account);

  @override
  bool delete(int id) => table.remove(id);

  @override
  void deleteAll() => table.removeAll();
}

class InMemoryBeneficiaryRepository implements BeneficiaryRepository {
  final InMemoryTable<BeneficiaryModel> table = InMemoryTable<BeneficiaryModel>(
    idOf: (BeneficiaryModel row) => row.id,
    assignId: (BeneficiaryModel row, int id) => row.id = id,
    clone: (BeneficiaryModel row) => row.copyWith(),
  );

  @override
  List<BeneficiaryModel> getAll() => table.all;

  @override
  BeneficiaryModel? get(int id) => table.get(id);

  @override
  int add(BeneficiaryModel beneficiary) => table.put(beneficiary);

  @override
  int update(BeneficiaryModel beneficiary) => table.put(beneficiary);

  @override
  bool delete(int id) => table.remove(id);

  @override
  void deleteAll() => table.removeAll();
}

class InMemoryExpenseRepository implements ExpenseRepository {
  final InMemoryTable<ExpenseModel> table = InMemoryTable<ExpenseModel>(
    idOf: (ExpenseModel row) => row.id,
    assignId: (ExpenseModel row, int id) => row.id = id,
    clone: (ExpenseModel row) => row.copyWith(),
  );

  @override
  List<ExpenseModel> getAll() => table.all;

  @override
  ExpenseModel? get(int id) => table.get(id);

  @override
  List<ExpenseModel> getActive() =>
      table.all.where((ExpenseModel row) => row.endDate == null).toList();

  @override
  List<ExpenseModel> getClosed() =>
      table.all.where((ExpenseModel row) => row.endDate != null).toList();

  @override
  List<ExpenseModel> getChain(int rootId) => table.all
      .where((ExpenseModel row) => row.parentId == rootId || row.id == rootId)
      .toList();

  @override
  int add(ExpenseModel expense) => table.put(expense);

  @override
  int update(ExpenseModel expense) => table.put(expense);

  @override
  bool delete(int id) => table.remove(id);

  @override
  void deleteAll() => table.removeAll();
}

class InMemoryRevenueRepository implements RevenueRepository {
  final InMemoryTable<RevenueModel> table = InMemoryTable<RevenueModel>(
    idOf: (RevenueModel row) => row.id,
    assignId: (RevenueModel row, int id) => row.id = id,
    clone: (RevenueModel row) => row.copyWith(),
  );

  @override
  List<RevenueModel> getAll() => table.all;

  @override
  RevenueModel? get(int id) => table.get(id);

  @override
  List<RevenueModel> getActive() =>
      table.all.where((RevenueModel row) => row.endDate == null).toList();

  @override
  List<RevenueModel> getClosed() =>
      table.all.where((RevenueModel row) => row.endDate != null).toList();

  @override
  List<RevenueModel> getChain(int rootId) => table.all
      .where((RevenueModel row) => row.parentId == rootId || row.id == rootId)
      .toList();

  @override
  int add(RevenueModel revenue) => table.put(revenue);

  @override
  int update(RevenueModel revenue) => table.put(revenue);

  @override
  bool delete(int id) => table.remove(id);

  @override
  void deleteAll() => table.removeAll();
}

class InMemoryTransferRepository implements TransferRepository {
  final InMemoryTable<TransferModel> table = InMemoryTable<TransferModel>(
    idOf: (TransferModel row) => row.id,
    assignId: (TransferModel row, int id) => row.id = id,
    clone: (TransferModel row) => row.copyWith(),
  );

  @override
  List<TransferModel> getAll() => table.all;

  @override
  TransferModel? get(int id) => table.get(id);

  @override
  List<TransferModel> getActive() =>
      table.all.where((TransferModel row) => row.endDate == null).toList();

  @override
  List<TransferModel> getClosed() =>
      table.all.where((TransferModel row) => row.endDate != null).toList();

  @override
  List<TransferModel> getChain(int rootId) => table.all
      .where((TransferModel row) => row.parentId == rootId || row.id == rootId)
      .toList();

  @override
  int add(TransferModel transfer) => table.put(transfer);

  @override
  int update(TransferModel transfer) => table.put(transfer);

  @override
  bool delete(int id) => table.remove(id);

  @override
  void deleteAll() => table.removeAll();
}

class InMemoryLoanRepository implements LoanRepository {
  final InMemoryTable<LoanModel> table = InMemoryTable<LoanModel>(
    idOf: (LoanModel row) => row.id,
    assignId: (LoanModel row, int id) => row.id = id,
    clone: (LoanModel row) => row.copyWith(),
  );

  @override
  List<LoanModel> getAll() => table.all;

  @override
  int add(LoanModel loan) => table.put(loan);

  @override
  int update(LoanModel loan) => table.put(loan);

  @override
  bool delete(int id) => table.remove(id);

  @override
  void deleteAll() => table.removeAll();
}

class InMemoryLoanEventRepository implements LoanEventRepository {
  final InMemoryTable<LoanEventModel> table = InMemoryTable<LoanEventModel>(
    idOf: (LoanEventModel row) => row.id,
    assignId: (LoanEventModel row, int id) => row.id = id,
    clone: (LoanEventModel row) => row.copyWith(),
  );

  @override
  List<LoanEventModel> getAll() => table.all;

  @override
  List<LoanEventModel> getForLoan(int loanId) =>
      table.all.where((LoanEventModel row) => row.loanId == loanId).toList();

  @override
  int add(LoanEventModel event) => table.put(event);

  @override
  int update(LoanEventModel event) => table.put(event);

  @override
  bool delete(int id) => table.remove(id);

  @override
  void deleteForLoan(int loanId) =>
      table.removeMany(getForLoan(loanId).map((LoanEventModel row) => row.id));

  @override
  void deleteAll() => table.removeAll();
}

class InMemoryCategoryOverrideRepository implements CategoryOverrideRepository {
  final InMemoryTable<CategoryOverrideModel> table =
      InMemoryTable<CategoryOverrideModel>(
        idOf: (CategoryOverrideModel row) => row.id,
        assignId: (CategoryOverrideModel row, int id) => row.id = id,
        clone: _cloneOverride,
      );

  @override
  Map<String, CategoryOverrideModel> getAll() =>
      <String, CategoryOverrideModel>{
        for (final CategoryOverrideModel row in table.all) row.slug: row,
      };

  @override
  CategoryOverrideModel? get(String slug) => table.all
      .where((CategoryOverrideModel row) => row.slug == slug)
      .firstOrNull;

  @override
  void save(CategoryOverrideModel override) {
    final CategoryOverrideModel? existing = get(override.slug);

    if (override.isEmpty) {
      if (existing != null) table.remove(existing.id);
      return;
    }

    table.put(override..id = existing?.id ?? 0);
  }

  @override
  void delete(String slug) {
    final CategoryOverrideModel? existing = get(slug);
    if (existing != null) table.remove(existing.id);
  }

  @override
  void deleteAll() => table.removeAll();
}

CategoryOverrideModel _cloneOverride(CategoryOverrideModel row) {
  return CategoryOverrideModel()
    ..id = row.id
    ..slug = row.slug
    ..name = row.name
    ..icon = row.icon
    ..color = row.color;
}

class InMemoryCategoryMemoryRepository implements CategoryMemoryRepository {
  final InMemoryTable<CategoryMemoryModel> table =
      InMemoryTable<CategoryMemoryModel>(
        idOf: (CategoryMemoryModel row) => row.id,
        assignId: (CategoryMemoryModel row, int id) => row.id = id,
        clone: _cloneMemory,
      );

  @override
  CategoryMemoryModel? get(String key) =>
      table.all.where((CategoryMemoryModel row) => row.key == key).firstOrNull;

  @override
  List<CategoryMemoryModel> getAll() => table.all;

  @override
  int count() => table.count;

  @override
  void put(CategoryMemoryModel entry) {
    final CategoryMemoryModel? existing = get(entry.key);
    if (existing != null && existing.id != entry.id) {
      throw UniqueViolationException(
        'Unique constraint violated on CategoryMemoryModel.key: ${entry.key}',
      );
    }
    table.put(entry);
  }

  @override
  void evictOldest(int count) {
    if (count <= 0) return;
    final List<CategoryMemoryModel> ordered = table.all
      ..sort(
        (CategoryMemoryModel a, CategoryMemoryModel b) =>
            a.updatedAt.compareTo(b.updatedAt),
      );
    table.removeMany(
      ordered.take(count).map((CategoryMemoryModel row) => row.id),
    );
  }

  @override
  void delete(String key) {
    final CategoryMemoryModel? existing = get(key);
    if (existing != null) table.remove(existing.id);
  }

  @override
  void deleteAll() => table.removeAll();
}

CategoryMemoryModel _cloneMemory(CategoryMemoryModel row) {
  return CategoryMemoryModel()
    ..id = row.id
    ..key = row.key
    ..slug = row.slug
    ..corrections = row.corrections
    ..useMemory = row.useMemory
    ..updatedAt = row.updatedAt;
}

class InMemoryTransactionEventRepository implements TransactionEventRepository {
  final InMemoryTable<TransactionEventModel> table =
      InMemoryTable<TransactionEventModel>(
        idOf: (TransactionEventModel row) => row.id,
        assignId: (TransactionEventModel row, int id) => row.id = id,
        clone: _cloneEvent,
      );

  @override
  List<TransactionEventModel> getForRoot(int rootId, TransactionType type) =>
      table.all
          .where(
            (TransactionEventModel row) =>
                row.rootId == rootId && row.typeEnum == type,
          )
          .toList();

  @override
  void add(TransactionEventModel event) => table.put(event);

  @override
  void deleteForRoot(int rootId, TransactionType type) => table.removeMany(
    getForRoot(rootId, type).map((TransactionEventModel row) => row.id),
  );

  @override
  void deleteAll() => table.removeAll();
}

TransactionEventModel _cloneEvent(TransactionEventModel row) {
  return TransactionEventModel()
    ..id = row.id
    ..rootId = row.rootId
    ..transactionType = row.transactionType
    ..change = row.change
    ..previousValue = row.previousValue
    ..nextValue = row.nextValue
    ..at = row.at;
}
