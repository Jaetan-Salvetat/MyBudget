import 'package:mybudget/domain/entities/user.dart';

abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Future<User> login(String email, String password);
  Future<User> register(String name, String email, String password);
  Future<void> logout();
}
