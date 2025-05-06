import 'package:get/get.dart';
import 'package:mybudget/core/services/isar_service.dart';
import 'package:mybudget/data/models/account_model.dart';

class AccountController extends GetxController {
  final RxList<AccountModel> accounts = <AccountModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    getAccounts();
  }
  
  Future<void> getAccounts() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final accountsList = await IsarService().getAllAccounts();
      accounts.value = accountsList;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> addAccount(AccountModel account) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      await IsarService().saveAccount(account);
      await getAccounts();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> updateAccount(AccountModel account) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      await IsarService().saveAccount(account);
      await getAccounts();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> deleteAccount(int id) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      await IsarService().deleteAccount(id);
      await getAccounts();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  void reset() {
    accounts.clear();
    error.value = '';
  }
}
