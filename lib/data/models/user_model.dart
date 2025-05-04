import 'package:appwrite/models.dart' as models;
import 'package:mybudget/domain/entities/user.dart';

class UserModel implements User {
  final String _id;
  final String _email;
  final String _name;
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['\$id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      isAuthenticated: json['isAuthenticated'] ?? true,
    );
  }

  factory UserModel.fromAppwriteAccount(models.User account) {
    return UserModel(
      id: account.$id,
      email: account.email,
      name: account.name,
      isAuthenticated: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'email': _email,
      'name': _name,
      'isAuthenticated': _isAuthenticated,
    };
  }

  @override
  String get id => _id;

  @override
  String get email => _email;

  @override
  String get name => _name;

  @override
  bool get isAuthenticated => _isAuthenticated;
}
