import 'package:hive/hive.dart';

abstract class BaseLocalDataSource<T> {
  final String boxName;
  
  BaseLocalDataSource(this.boxName);
  
  Future<Box<T>> _openBox() async {
    return await Hive.openBox<T>(boxName);
  }
  
  Future<String> create(T item, String id) async {
    final box = await _openBox();
    await box.put(id, item);
    return id;
  }
  
  Future<T?> get(String id) async {
    final box = await _openBox();
    return box.get(id);
  }
  
  Future<List<T>> getAll() async {
    final box = await _openBox();
    return box.values.toList();
  }
  
  Future<void> update(String id, T item) async {
    final box = await _openBox();
    await box.put(id, item);
  }
  
  Future<void> delete(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }
  
  Future<void> clear() async {
    final box = await _openBox();
    await box.clear();
  }
}
