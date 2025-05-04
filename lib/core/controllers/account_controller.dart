import 'package:get/get.dart';
import 'package:mybudget/core/controllers/auth_controller.dart';
import 'package:mybudget/core/services/appwrite/index.dart';
import 'package:mybudget/data/models/account_model.dart';

class AccountController extends GetxController {
  final RxList<AccountModel> accounts = <AccountModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    ever(Get.find<AuthController>().user, (_) => getAccounts());
  }
  
  Future<void> getAccounts() async {
    try {
      if (!Get.find<AuthController>().isAuthenticated) return;
      
      isLoading.value = true;
      error.value = '';
      
      final accountsList = await AppwriteAccountService.getAccounts();
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
      
      await AppwriteAccountService.createAccount(account.name, account.bank);
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
      
      await AppwriteAccountService.updateAccount(account);
      await getAccounts();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> deleteAccount(String id) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      await AppwriteAccountService.deleteAccount(id);
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
