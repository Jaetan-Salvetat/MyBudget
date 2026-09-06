import 'package:mybudget/core/entities/filterable_transaction.dart';
import 'package:mybudget/core/entities/stored_frequency.dart';

abstract interface class RecurringTransaction<T extends RecurringTransaction<T>>
    implements FilterableTransaction, StoredFrequency {
  int get id;
  int? get parentId;
  set categorySlug(String? value);

  T closedOn(DateTime endDate);
  T forkedAt(DateTime startDate, int rootId);
}
