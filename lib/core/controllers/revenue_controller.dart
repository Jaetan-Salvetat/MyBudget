import 'package:get/get.dart';
import 'package:mybudget/core/controllers/auth_controller.dart';
import 'package:mybudget/core/services/appwrite/index.dart';
import 'package:mybudget/data/models/revenue_model.dart';

class RevenueController extends GetxController {
  final RxList<RevenueModel> revenues = <RevenueModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    ever(Get.find<AuthController>().user, (_) => getRevenues());
  }
  
  Future<void> getRevenues() async {
    try {
      if (!Get.find<AuthController>().isAuthenticated) return;
      
      isLoading.value = true;
      error.value = '';
      
      final revenuesList = await AppwriteRevenueService.getRevenues();
      revenues.value = revenuesList;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> addRevenue(RevenueModel revenue) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      await AppwriteRevenueService.createRevenue(revenue);
      await getRevenues();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> updateRevenue(RevenueModel revenue) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      await AppwriteRevenueService.updateRevenue(revenue);
      await getRevenues();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> deleteRevenue(String id) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      await AppwriteRevenueService.deleteRevenue(id);
      await getRevenues();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  void reset() {
    revenues.clear();
    error.value = '';
  }
}
