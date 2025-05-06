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
  
  double getMonthlyRevenues() {
    if (revenues.isEmpty) return 0.0;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return revenues
        .where(
          (revenue) =>
              revenue.date.isAtSameMomentAs(startOfMonth) ||
              revenue.date.isAtSameMomentAs(endOfMonth) ||
              (revenue.date.isAfter(startOfMonth) &&
              revenue.date.isBefore(endOfMonth)),
        )
        .fold(0.0, (sum, revenue) => sum + revenue.amount);
  }
  
  List<RevenueModel> getRecentRevenues(int count) {
    final sortedRevenues = [...revenues];
    sortedRevenues.sort((a, b) => b.date.compareTo(a.date));
    return sortedRevenues.take(count).toList();
  }
  
  double getTotalRevenues() {
    return revenues.fold(0.0, (sum, revenue) => sum + revenue.amount);
  }
  
  List<RevenueModel> getRevenuesForAccount(int accountId) {
    return revenues.where((revenue) => revenue.accountId == accountId).toList();
  }
}
