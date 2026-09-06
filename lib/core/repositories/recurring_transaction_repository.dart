import 'package:objectbox/objectbox.dart';

abstract class RecurringTransactionRepository<T> {
  RecurringTransactionRepository(
    this._box,
    this._idProperty,
    this._endDateProperty,
    this._parentIdProperty,
  );

  final Box<T> _box;
  final QueryIntegerProperty<T> _idProperty;
  final QueryDateProperty<T> _endDateProperty;
  final QueryIntegerProperty<T> _parentIdProperty;

  List<T> getAll() => _box.getAll();

  T? get(int id) => _box.get(id);

  List<T> getActive() => _find(_endDateProperty.isNull());

  List<T> getClosed() => _find(_endDateProperty.notNull());

  List<T> getChain(int rootId) =>
      _find(_parentIdProperty.equals(rootId) | _idProperty.equals(rootId));

  int add(T entity) => _box.put(entity);

  int update(T entity) => _box.put(entity);

  bool delete(int id) => _box.remove(id);

  void deleteAll() => _box.removeAll();

  List<T> _find(Condition<T> condition) {
    final query = _box.query(condition).build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }
}
