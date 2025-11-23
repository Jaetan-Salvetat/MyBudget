import 'package:mybudget/models/category_model.dart';
import 'package:objectbox/objectbox.dart';

class CategoryRepository {
  final Box<CategoryModel> _box;

  CategoryRepository(this._box);

  List<CategoryModel> getAll() {
    return _box.getAll();
  }

  CategoryModel? get(int id) {
    return _box.get(id);
  }

  int add(CategoryModel category) {
    return _box.put(category);
  }

  int update(CategoryModel category) {
    return _box.put(category);
  }

  bool delete(int id) {
    return _box.remove(id);
  }

  void deleteAll() {
    _box.removeAll();
  }
}
