import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/services/appwrite_service.dart';
import 'package:mybudget/data/models/user_model.dart';

final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  final account = ref.watch(appwriteAccountProvider);
  return AuthDataSourceImpl(account);
});

abstract class AuthDataSource {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String name, String email, String password);
  Future<void> logout();
}

class AuthDataSourceImpl implements AuthDataSource {
  final Account _account;

  AuthDataSourceImpl(this._account);

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = await _account.get();
      return _mapUserToUserModel(user);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      await _account.createEmailPasswordSession(
        email: email,
        password: password
      );
      
      final user = await _account.get();
      return _mapUserToUserModel(user);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<UserModel> register(String name, String email, String password) async {
    try {
      final user = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name
      );
      
      await _account.createEmailPasswordSession(
        email: email,
        password: password
      );
      
      return _mapUserToUserModel(user);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _account.deleteSessions();
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  UserModel _mapUserToUserModel(models.User user) {
    return UserModel(
      id: user.$id,
      email: user.email,
      name: user.name,
      isAuthenticated: true
    );
  }

  Exception _handleAuthException(dynamic e) {
    if (e is AppwriteException) {
      switch (e.code) {
        case 401:
          return Exception('Email ou mot de passe incorrect');
        case 409:
          return Exception('Un compte existe déjà avec cet email');
        case 429:
          return Exception('Trop de tentatives de connexion, réessayez plus tard');
        default:
          return Exception('Erreur de connexion: ${e.message}');
      }
    }
    return Exception('Erreur inconnue: $e');
  }
}
