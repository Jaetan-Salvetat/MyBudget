import 'package:mybudget/core/entities/stored_frequency.dart';
import 'package:mybudget/core/repositories/recurring_transaction_repository.dart';

class FrequencyStorageMigration {
  const FrequencyStorageMigration._();

  static int run<T extends StoredFrequency>(
    RecurringTransactionRepository<T> repository,
  ) {
    var rewritten = 0;
    for (final entity in repository.getAll()) {
      final canonical = entity.frequencyEnum;
      if (entity.storedFrequency == canonical.storageKey) continue;

      entity.frequencyEnum = canonical;
      repository.update(entity);
      rewritten++;
    }
    return rewritten;
  }
}
