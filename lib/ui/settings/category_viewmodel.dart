import 'package:flutter/material.dart';
import 'package:mybudget/core/repositories/category_repository.dart';
import 'package:mybudget/models/category_model.dart';

import 'package:mybudget/core/services/preferences_service.dart';

class CategoryViewModel extends ChangeNotifier {
  final CategoryRepository _categoryRepository;

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String _error = '';

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String get error => _error;

  CategoryViewModel(this._categoryRepository) {
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      _isLoading = true;
      notifyListeners();

      if (!PreferencesService.isCategoriesCreated()) {
        await _initDefaultCategories();
        await PreferencesService.setCategoriesCreated();
      }

      _categories = _categoryRepository.getAll();

      _categories.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _initDefaultCategories() async {
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

    for (var category in defaultCategories) {
      _categoryRepository.add(category);
    }
  }

  Future<void> addCategory(CategoryModel category) async {
    try {
      _isLoading = true;
      notifyListeners();

      _categoryRepository.add(category);
      await _loadCategories();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    try {
      _isLoading = true;
      notifyListeners();

      _categoryRepository.update(category);
      await _loadCategories();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      _isLoading = true;
      notifyListeners();

      _categoryRepository.delete(id);
      await _loadCategories();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  CategoryModel? getCategoryById(int id) {
    try {
      return _categoryRepository.get(id);
    } catch (e) {
      return null;
    }
  }
}
