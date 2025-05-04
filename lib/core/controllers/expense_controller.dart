import 'package:get/get.dart';
import 'package:mybudget/core/controllers/auth_controller.dart';
import 'package:mybudget/core/services/appwrite/index.dart';
import 'package:mybudget/data/models/expense_model.dart';

class ExpenseController extends GetxController {
  final RxList<ExpenseModel> expenses = <ExpenseModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    ever(Get.find<AuthController>().user, (_) => getExpenses());
  }
  
  Future<void> getExpenses() async {
    try {
      if (!Get.find<AuthController>().isAuthenticated) return;
      
      isLoading.value = true;
      error.value = '';
      
      final expensesList = await AppwriteExpenseService.getExpenses();
      expenses.value = expensesList;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> addExpense(ExpenseModel expense) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      await AppwriteExpenseService.createExpense(expense);
      await getExpenses();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      await AppwriteExpenseService.updateExpense(expense);
      await getExpenses();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> deleteExpense(String id) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      await AppwriteExpenseService.deleteExpense(id);
      await getExpenses();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  void reset() {
    expenses.clear();
    error.value = '';
  }
}
