import 'package:hive/hive.dart';
import 'package:mybudget/domain/entities/user.dart';

part 'user_model.g.dart';

@HiveType(typeId: 5)
class UserModel implements User {
  @HiveField(0)
  final String _id;

  @HiveField(1)
  final String _email;

  @HiveField(2)
  final String _name;

  @HiveField(3)
  final bool _isAuthenticated;

  UserModel({
    required String id,
    required String email,
    required String name,
    required bool isAuthenticated,
  })  : _id = id,
        _email = email,
        _name = name,
        _isAuthenticated = isAuthenticated;

  @override
  String get id => _id;

  @override
  String get email => _email;

  @override
  String get name => _name;

  @override
  bool get isAuthenticated => _isAuthenticated;
}
