import 'package:get/get.dart';
import 'package:mybudget/core/services/isar_service.dart';
import 'package:mybudget/data/models/expense_model.dart';

class ExpenseController extends GetxController {
  final RxList<ExpenseModel> expenses = <ExpenseModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    getExpenses();
  }
  
  Future<void> getExpenses() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final expensesList = await IsarService().getAllExpenses();
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
      
      await IsarService().saveExpense(expense);
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
      
      await IsarService().saveExpense(expense);
      await getExpenses();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> deleteExpense(int id) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      await IsarService().deleteExpense(id);
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
