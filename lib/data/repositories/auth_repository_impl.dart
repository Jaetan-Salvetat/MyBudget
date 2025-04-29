import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/data/datasources/auth_datasource.dart';
import 'package:mybudget/domain/entities/user.dart';
import 'package:mybudget/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authDataSource = ref.watch(authDataSourceProvider);
  return AuthRepositoryImpl(authDataSource);
});

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _authDataSource;

  AuthRepositoryImpl(this._authDataSource);

  @override
  Future<User?> getCurrentUser() async {
    return await _authDataSource.getCurrentUser();
  }

  @override
  Future<User> login(String email, String password) async {
    return await _authDataSource.login(email, password);
  }

  @override
  Future<User> register(String name, String email, String password) async {
    return await _authDataSource.register(name, email, password);
  }

  @override
  Future<void> logout() async {
    await _authDataSource.logout();
  }
}
