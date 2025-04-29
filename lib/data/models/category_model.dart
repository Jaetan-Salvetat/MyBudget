import 'package:hive/hive.dart';
import 'package:mybudget/domain/entities/category.dart';

part 'category_model.g.dart';

@HiveType(typeId: 4)
class CategoryModel implements Category {
  @HiveField(0)
  final String _id;

  @HiveField(1)
  final String _name;

  @HiveField(2)
  final String _icon;

  CategoryModel({
    required String id,
    required String name,
    required String icon,
  })  : _id = id,
        _name = name,
        _icon = icon;

  @override
  String get id => _id;

  @override
  String get name => _name;

  @override
  String get icon => _icon;
}
