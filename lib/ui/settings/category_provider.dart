import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'category_provider.g.dart';

@Riverpod(keepAlive: true)
class CategoryNotifier extends _$CategoryNotifier {
  @override
  Future<List<CategoryModel>> build() async {
    final repo = ref.watch(categoryRepositoryProvider);

    if (!PreferencesService.isCategoriesCreated()) {
      await _initDefaultCategories(repo);
      await PreferencesService.setCategoriesCreated();
    }

    final categories = repo.getAll();
    categories.sort((a, b) => a.name.compareTo(b.name));
    return categories;
  }

  Future<void> _initDefaultCategories(dynamic repo) async {
    for (final def in CategoryDefaults.defaultCategories) {
      repo.add(CategoryModel.create(
        name: def.name,
        icon: def.icon,
        color: def.color,
        scope: def.scope,
      ));
    }
  }

  Future<void> addCategory(CategoryModel category) async {
    try {
      final repo = ref.read(categoryRepositoryProvider);
      repo.add(category);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    try {
      final repo = ref.read(categoryRepositoryProvider);
      repo.update(category);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      final repo = ref.read(categoryRepositoryProvider);
      repo.delete(id);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  CategoryModel? getCategoryById(int id) {
    final repo = ref.read(categoryRepositoryProvider);
    try {
      return repo.get(id);
    } catch (e) {
      return null;
    }
  }
}
