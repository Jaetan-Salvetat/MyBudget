import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:mybudget/data/models/user_model.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl();
});

abstract class AuthLocalDataSource {
  Future<UserModel?> getUser();
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String name, String email, String password);
  Future<void> logout();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  @override
  Future<UserModel?> getUser() async {
    final userBox = await Hive.openBox<UserModel>('user');
    if (userBox.isEmpty) {
      return null;
    }
    return userBox.getAt(0);
  }

  @override
  Future<UserModel> login(String email, String password) async {
    final userBox = await Hive.openBox<UserModel>('user');
    final credentialsBox = await Hive.openBox('credentials');
    
    // Vérifier si l'utilisateur existe
    final storedEmail = credentialsBox.get('email');
    final storedPasswordHash = credentialsBox.get('passwordHash');
    
    if (storedEmail == null || storedPasswordHash == null) {
      throw Exception('Aucun compte trouvé avec cet email');
    }
    
    if (storedEmail != email) {
      throw Exception('Email incorrect');
    }
    
    // Vérifier le mot de passe
    final passwordHash = _hashPassword(password);
    if (passwordHash != storedPasswordHash) {
      throw Exception('Mot de passe incorrect');
    }
    
    // Récupérer l'utilisateur
    UserModel user = userBox.isEmpty ? 
        UserModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          email: email,
          name: credentialsBox.get('name') ?? 'Utilisateur',
          isAuthenticated: true,
        ) : 
        UserModel(
          id: userBox.getAt(0)!.id,
          email: email,
          name: userBox.getAt(0)!.name,
          isAuthenticated: true,
        );
    
    await userBox.clear();
    await userBox.add(user);
    
    return user;
  }

  @override
  Future<UserModel> register(String name, String email, String password) async {
    final userBox = await Hive.openBox<UserModel>('user');
    final credentialsBox = await Hive.openBox('credentials');
    
    // Vérifier si un compte existe déjà
    final storedEmail = credentialsBox.get('email');
    if (storedEmail != null && storedEmail == email) {
      throw Exception('Un compte existe déjà avec cet email');
    }
    
    // Stocker les identifiants
    final passwordHash = _hashPassword(password);
    await credentialsBox.put('email', email);
    await credentialsBox.put('passwordHash', passwordHash);
    await credentialsBox.put('name', name);
    
    // Créer l'utilisateur
    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: name,
      isAuthenticated: true,
    );
    
    await userBox.clear();
    await userBox.add(user);
    
    return user;
  }

  @override
  Future<void> logout() async {
    final userBox = await Hive.openBox<UserModel>('user');
    if (!userBox.isEmpty) {
      final currentUser = userBox.getAt(0)!;
      final loggedOutUser = UserModel(
        id: currentUser.id,
        email: currentUser.email,
        name: currentUser.name,
        isAuthenticated: false,
      );
      
      await userBox.clear();
      await userBox.add(loggedOutUser);
    }
  }
  
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
