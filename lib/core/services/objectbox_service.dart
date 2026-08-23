import 'package:path_provider/path_provider.dart';
import 'package:mybudget/models/beneficiary_model.dart';
import 'package:mybudget/models/category_memory_model.dart';
import 'package:mybudget/models/category_override_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/legacy_category_model.dart';
import 'package:mybudget/models/loan_event_model.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/models/transfer_model.dart';
import 'package:path/path.dart' as p;

import 'package:mybudget/objectbox.g.dart';

class ObjectBoxService {
  late Store store;

  late Box<BeneficiaryModel> beneficiaryBox;
  late Box<CategoryOverrideModel> categoryOverrideBox;
  late Box<CategoryMemoryModel> categoryMemoryBox;
  late Box<ExpenseModel> expenseBox;
  late Box<RevenueModel> revenueBox;
  late Box<AccountModel> accountBox;
  late Box<LoanModel> loanBox;
  late Box<LoanEventModel> loanEventBox;
  late Box<TransferModel> transferBox;
  late Box<LegacyCategoryModel> legacyCategoryBox;

  static ObjectBoxService? _instance;

  ObjectBoxService._();

  static Future<ObjectBoxService> getInstance() async {
    if (_instance == null) {
      _instance = ObjectBoxService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final storeDir = p.join(docsDir.path, "objectbox");
    store = await openStore(directory: storeDir);

    beneficiaryBox = Box<BeneficiaryModel>(store);
    categoryOverrideBox = Box<CategoryOverrideModel>(store);
    categoryMemoryBox = Box<CategoryMemoryModel>(store);
    expenseBox = Box<ExpenseModel>(store);
    revenueBox = Box<RevenueModel>(store);
    accountBox = Box<AccountModel>(store);
    loanBox = Box<LoanModel>(store);
    loanEventBox = Box<LoanEventModel>(store);
    transferBox = Box<TransferModel>(store);
    legacyCategoryBox = Box<LegacyCategoryModel>(store);
  }

  void closeStore() {
    if (!store.isClosed()) {
      store.close();
    }
  }

  static Future<void> resetInstance() async {
    if (_instance != null) {
      _instance!.closeStore();
      _instance = null;
    }
  }

  Future<void> clearAllData() async {
    beneficiaryBox.removeAll();
    categoryOverrideBox.removeAll();
    categoryMemoryBox.removeAll();
    expenseBox.removeAll();
    revenueBox.removeAll();
    accountBox.removeAll();
    loanBox.removeAll();
    loanEventBox.removeAll();
    transferBox.removeAll();
  }
}
