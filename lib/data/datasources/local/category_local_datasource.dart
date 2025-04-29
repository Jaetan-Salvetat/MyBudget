import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:mybudget/data/models/category_model.dart';

final categoryLocalDataSourceProvider = Provider<CategoryLocalDataSource>((ref) {
  return CategoryLocalDataSourceImpl();
});

abstract class CategoryLocalDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<CategoryModel> getCategory(String id);
  Future<void> create(CategoryModel category, String id);
  Future<void> updateCategory(CategoryModel category);
  Future<void> deleteCategory(String id);
}

class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  @override
  Future<void> create(CategoryModel category, String id) async {
    final categoryBox = await Hive.openBox<CategoryModel>('categories');
    await categoryBox.put(id, category);
  }

  @override
  Future<void> deleteCategory(String id) async {
    final categoryBox = await Hive.openBox<CategoryModel>('categories');
    await categoryBox.delete(id);
  }

  @override
  Future<CategoryModel> getCategory(String id) async {
    final categoryBox = await Hive.openBox<CategoryModel>('categories');
    return categoryBox.get(id)!;
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    final categoryBox = await Hive.openBox<CategoryModel>('categories');
    return categoryBox.values.toList();
  }

  @override
  Future<void> updateCategory(CategoryModel category) async {
    final categoryBox = await Hive.openBox<CategoryModel>('categories');
    await categoryBox.put(category.id, category);
  }
}
