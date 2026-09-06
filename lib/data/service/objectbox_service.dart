import 'package:mybudget/data/repository/expense_repository.dart';
import 'package:mybudget/data/repository/revenue_repository.dart';
import 'package:mybudget/data/repository/transfer_repository.dart';
import 'package:mybudget/data/service/data/frequency_storage_migration.dart';
import 'package:mybudget/objectbox.g.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ObjectBoxService {
  ObjectBoxService._();

  static ObjectBoxService? _instance;

  late final Store store;

  Admin? _admin;

  static Future<ObjectBoxService> getInstance() async {
    final existing = _instance;
    if (existing != null) return existing;

    final service = ObjectBoxService._();
    await service._init();
    _instance = service;
    return service;
  }

  static Future<void> resetInstance() async {
    _instance?.closeStore();
    _instance = null;
  }

  Future<void> _init() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final storeDir = p.join(docsDir.path, 'objectbox');
    store = await openStore(directory: storeDir);
    if (Admin.isAvailable()) _admin = Admin(store);

    _canonicalizeStoredFrequencies();
  }

  void _canonicalizeStoredFrequencies() {
    FrequencyStorageMigration.run(ExpenseRepository(store));
    FrequencyStorageMigration.run(RevenueRepository(store));
    FrequencyStorageMigration.run(TransferRepository(store));
  }

  void closeStore() {
    _admin?.close();
    _admin = null;
    if (!store.isClosed()) {
      store.close();
    }
  }
}
