import 'package:get/get.dart';
import 'package:mybudget/core/controllers/account_controller.dart';
import 'package:mybudget/core/controllers/category_controller.dart';
import 'package:mybudget/core/controllers/expense_controller.dart';
import 'package:mybudget/core/controllers/revenue_controller.dart';

class DataLoadingService {
  static Future<void> loadAllData() async {
    // Chargement des comptes
    await Get.find<AccountController>().getAccounts();
    
    // Chargement des catégories
    await Get.find<CategoryController>().getCategories();
    
    // Chargement des dépenses
    await Get.find<ExpenseController>().getExpenses();
    
    // Chargement des revenus
    await Get.find<RevenueController>().getRevenues();
  }
}
