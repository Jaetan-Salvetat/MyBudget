import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:get/get.dart';
import 'package:mybudget/core/services/appwrite_service.dart';
import 'package:mybudget/data/models/user_model.dart';

class AuthDatasource {
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = await _appwriteService.account.get();
      return _mapUserToUserModel(user);
    } catch (e) {
      return null;
    }
  }

  Future<UserModel> login(String email, String password) async {
    try {
      await _appwriteService.account.createEmailPasswordSession(
        email: email,
        password: password
      );
      
      final user = await _appwriteService.account.get();
      return _mapUserToUserModel(user);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserModel> register(String name, String email, String password) async {
    try {
      final user = await _appwriteService.account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name
      );
      
      await _appwriteService.account.createEmailPasswordSession(
        email: email,
        password: password
      );
      
      return _mapUserToUserModel(user);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> logout() async {
    try {
      await _appwriteService.account.deleteSession(sessionId: 'current');
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _appwriteService.account.createRecovery(
        email: email,
        url: 'https://mybudget.com/reset-password'
      );
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
      if (e.code == 401) {
        return Exception('Email ou mot de passe incorrect');
      } else if (e.code == 409) {
        return Exception('Un compte existe déjà avec cette adresse email');
      } else if (e.code == 429) {
        return Exception('Trop de tentatives, veuillez réessayer plus tard');
      }
      return Exception('Erreur: ${e.message}');
    }
    return Exception('Une erreur est survenue: ${e.toString()}');
  }
}
