import 'package:flutter/material.dart';
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
    final defaultCategories = [
      CategoryModel.create(
        name: 'Alimentation',
        icon: 'restaurant',
        color: Colors.orange.toARGB32(),
      ),
      CategoryModel.create(
        name: 'Logement',
        icon: 'home',
        color: Colors.blue.toARGB32(),
      ),
      CategoryModel.create(
        name: 'Transport',
        icon: 'directions_car',
        color: Colors.green.toARGB32(),
      ),
      CategoryModel.create(
        name: 'Loisirs',
        icon: 'sports_esports',
        color: Colors.purple.toARGB32(),
      ),
      CategoryModel.create(
        name: 'Santé',
        icon: 'medical_services',
        color: Colors.red.toARGB32(),
      ),
      CategoryModel.create(
        name: 'Shopping',
        icon: 'shopping_bag',
        color: Colors.pink.toARGB32(),
      ),
      CategoryModel.create(
        name: 'Salaire',
        icon: 'account_balance_wallet',
        color: Colors.teal.toARGB32(),
      ),
      CategoryModel.create(
        name: 'Divers',
        icon: 'more_horiz',
        color: Colors.grey.toARGB32(),
      ),
    ];

    for (final category in defaultCategories) {
      repo.add(category);
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
