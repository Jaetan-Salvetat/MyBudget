import 'package:get/get.dart';
import 'package:mybudget/core/services/isar_service.dart';
import 'package:mybudget/data/models/revenue_model.dart';

class RevenueController extends GetxController {
  final RxList<RevenueModel> revenues = <RevenueModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    getRevenues();
  }
  
  Future<void> getRevenues() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final revenuesList = await IsarService().getAllRevenues();
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
      
      await IsarService().saveRevenue(revenue);
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
      
      await IsarService().saveRevenue(revenue);
      await getRevenues();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> deleteRevenue(int id) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      await IsarService().deleteRevenue(id);
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
