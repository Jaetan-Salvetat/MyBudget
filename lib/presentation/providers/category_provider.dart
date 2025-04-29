import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/data/models/category_model.dart';
import 'package:mybudget/domain/entities/category.dart';
import 'package:mybudget/domain/repositories/category_repository.dart';
import 'package:mybudget/data/repositories/category_repository_impl.dart';

final categoryNotifierProvider = StateNotifierProvider<CategoryNotifier, List<Category>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategoryNotifier(repository);
});

class CategoryNotifier extends StateNotifier<List<Category>> {
  final CategoryRepository _repository;

  CategoryNotifier(this._repository) : super([]) {
    getCategories();
  }

  Future<void> getCategories() async {
    final categories = await _repository.getCategories();
    if (categories.isEmpty) {
      await _initializeDefaultCategories();
      state = await _repository.getCategories();
    } else {
      state = categories;
    }
  }

  void addCategory(Category category) async {
    await _repository.addCategory(category);
    await getCategories();
  }

  void updateCategory(Category category) async {
    await _repository.updateCategory(category);
    await getCategories();
  }

  void deleteCategory(String id) async {
    await _repository.deleteCategory(id);
    await getCategories();
  }

  Future<void> _initializeDefaultCategories() async {
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
      await _repository.addCategory(category);
    }
  }
}
