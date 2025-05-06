import 'package:get/get.dart';
import 'package:mybudget/core/services/isar_service.dart';
import 'package:mybudget/data/models/category_model.dart';

class CategoryController extends GetxController {
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    getCategories();
  }
  
  Future<void> getCategories() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final categoriesList = await IsarService().getAllCategories();
      if (categoriesList.isEmpty) {
        await _initializeDefaultCategories();
        categories.value = await IsarService().getAllCategories();
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
      
      await IsarService().saveCategory(category);
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
      
      await IsarService().saveCategory(category);
      await getCategories();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> deleteCategory(int id) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      await IsarService().deleteCategory(id);
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
        CategoryModel.create(name: 'Alimentation', icon: 'restaurant'),
        CategoryModel.create(name: 'Transport', icon: 'directions_car'),
        CategoryModel.create(name: 'Logement', icon: 'home'),
        CategoryModel.create(name: 'Loisirs', icon: 'sports_esports'),
        CategoryModel.create(name: 'Santé', icon: 'medical_services'),
        CategoryModel.create(name: 'Vêtements', icon: 'checkroom'),
        CategoryModel.create(name: 'Autre', icon: 'more_horiz'),
      ];

      for (final category in defaultCategories) {
        await IsarService().saveCategory(category);
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
