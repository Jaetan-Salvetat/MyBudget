import 'package:mybudget/core/contracts/filterable_transaction.dart';
import 'package:mybudget/core/contracts/stored_frequency.dart';

abstract interface class RecurringTransaction<T extends RecurringTransaction<T>>
    implements FilterableTransaction, StoredFrequency {
  int get id;
  int? get parentId;
  set categorySlug(String? value);

  T closedOn(DateTime endDate);
  T forkedAt(DateTime startDate, int rootId);
}
