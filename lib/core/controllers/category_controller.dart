import 'package:get/get.dart';
import 'package:mybudget/core/controllers/auth_controller.dart';
import 'package:mybudget/core/services/appwrite/index.dart';
import 'package:mybudget/data/models/category_model.dart';

class CategoryController extends GetxController {
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    ever(Get.find<AuthController>().user, (_) => getCategories());
  }
  
  Future<void> getCategories() async {
    try {
      if (!Get.find<AuthController>().isAuthenticated) return;
      
      isLoading.value = true;
      error.value = '';
      
      final categoriesList = await AppwriteCategoryService.getCategories();
      if (categoriesList.isEmpty) {
        await _initializeDefaultCategories();
        categories.value = await AppwriteCategoryService.getCategories();
      } else {
        categories.value = categoriesList;
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> addCategory(CategoryModel category) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      await AppwriteCategoryService.createCategory(category);
      await getCategories();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> updateCategory(CategoryModel category) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      await AppwriteCategoryService.updateCategory(category);
      await getCategories();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> deleteCategory(String id) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      await AppwriteCategoryService.deleteCategory(id);
      await getCategories();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> _initializeDefaultCategories() async {
    try {
      final defaultCategories = [
        CategoryModel(id: '1', name: 'Alimentation', icon: 'restaurant'),
        CategoryModel(id: '2', name: 'Transport', icon: 'directions_car'),
        CategoryModel(id: '3', name: 'Logement', icon: 'home'),
        CategoryModel(id: '4', name: 'Loisirs', icon: 'sports_esports'),
        CategoryModel(id: '5', name: 'Santé', icon: 'medical_services'),
        CategoryModel(id: '6', name: 'Vêtements', icon: 'checkroom'),
        CategoryModel(id: '7', name: 'Autre', icon: 'more_horiz'),
      ];

      for (final category in defaultCategories) {
        await AppwriteCategoryService.createCategory(category);
      }
    } catch (e) {
      error.value = e.toString();
    }
  }
  
  void reset() {
    categories.clear();
    error.value = '';
  }
}
