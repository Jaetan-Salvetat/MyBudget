import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/data/datasources/local/category_local_datasource.dart';
import 'package:mybudget/data/models/category_model.dart';
import 'package:mybudget/domain/entities/category.dart';
import 'package:mybudget/domain/repositories/category_repository.dart';
import 'package:uuid/uuid.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final localDataSource = ref.watch(categoryLocalDataSourceProvider);
  return CategoryRepositoryImpl(localDataSource);
});

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDataSource _localDataSource;
  final Uuid _uuid = const Uuid();
  
  CategoryRepositoryImpl(this._localDataSource);

  @override
  Future<void> addCategory(Category category) async {
    final categoryModel = CategoryModel(
      id: category.id,
      name: category.name,
      icon: category.icon,
    );
    
    await _localDataSource.create(categoryModel, category.id);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _localDataSource.deleteCategory(id);
  }

  @override
  Future<List<Category>> getCategories() async {
    return await _localDataSource.getCategories();
  }

  @override
  Future<void> updateCategory(Category category) async {
    final categoryModel = CategoryModel(
      id: category.id,
      name: category.name,
      icon: category.icon,
    );
    
    await _localDataSource.updateCategory(categoryModel);
  }
  
  Future<Category> createCategory(String name, String icon) async {
    final id = _uuid.v4();
    final category = CategoryModel(
      id: id,
      name: name,
      icon: icon,
    );
    
    await _localDataSource.create(category, id);
    return category;
  }
}
