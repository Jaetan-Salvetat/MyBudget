import 'package:mybudget/data/datasources/auth_datasource.dart';
import 'package:mybudget/data/models/user_model.dart';
import 'package:mybudget/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDatasource _authDatasource;

  AuthRepositoryImpl() : _authDatasource = AuthDatasource();

  @override
  Future<UserModel?> getCurrentUser() async {
    return await _authDatasource.getCurrentUser();
  }

  @override
  Future<UserModel> login(String email, String password) async {
    return await _authDatasource.login(email, password);
  }

  @override
  Future<UserModel> register(String name, String email, String password) async {
    return await _authDatasource.register(name, email, password);
  }

  @override
  Future<void> logout() async {
    await _authDatasource.logout();
  }

  Future<void> resetPassword(String email) async {
    await _authDatasource.resetPassword(email);
  }
}
