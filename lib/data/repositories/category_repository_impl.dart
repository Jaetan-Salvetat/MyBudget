import 'package:appwrite/appwrite.dart';
import 'package:mybudget/data/datasources/category_datasource.dart';
import 'package:mybudget/data/models/category_model.dart';
import 'package:mybudget/domain/entities/category.dart';
import 'package:mybudget/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryDatasource _categoryDatasource;

  CategoryRepositoryImpl() : _categoryDatasource = CategoryDatasource();

  @override
  Future<void> addCategory(Category category) async {
    if (category is CategoryModel) {
      await _categoryDatasource.createCategory(category);
    } else {
      final categoryModel = CategoryModel(
        id: category.id,
        name: category.name,
        icon: category.icon
      );
      await _categoryDatasource.createCategory(categoryModel);
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _categoryDatasource.deleteCategory(id);
  }

  @override
  Future<List<Category>> getCategories() async {
    return await _categoryDatasource.getCategories();
  }

  Future<Category?> getCategory(String id) async {
    return await _categoryDatasource.getCategory(id);
  }

  @override
  Future<void> updateCategory(Category category) async {
    if (category is CategoryModel) {
      await _categoryDatasource.updateCategory(category);
    } else {
      final categoryModel = CategoryModel(
        id: category.id,
        name: category.name,
        icon: category.icon
      );
      await _categoryDatasource.updateCategory(categoryModel);
    }
  }

  Future<Category> createCategory(String name, String icon) async {
    final category = CategoryModel(
      id: ID.unique(),
      name: name,
      icon: icon
    );
    return await _categoryDatasource.createCategory(category);
  }
}
