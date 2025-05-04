import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:appwrite/models.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mybudget/core/routes/app_routes.dart';
import 'package:mybudget/core/services/appwrite_service.dart';
import 'package:mybudget/core/services/data_loading_service.dart';
import 'package:mybudget/data/models/user_model.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';

class AuthController extends GetxController {
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxBool isEmailVerified = true.obs; // Toujours considérer comme vérifié avec auth SMS

  bool get isAuthenticated => user.value != null && user.value!.isAuthenticated;

  @override
  void onInit() {
    super.onInit();
    getCurrentUser();
  }

  Future<void> getCurrentUser() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final appwrite = Get.find<AppwriteService>();
      
      try {
        final account = await appwrite.account.get();
        // Avec auth SMS, on considère toujours l'email comme vérifié
        isEmailVerified.value = true;
        user.value = UserModel.fromAppwriteAccount(account);
        await DataLoadingService.loadAllData();
      } catch (e) {
        user.value = null;
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Démarrer l'authentification par téléphone (envoyer SMS)
  Future<Token?> startPhoneAuthentication(String phoneNumber) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      print('AuthController: Début authentication téléphone');
      print('AuthController: Numéro reçu: "$phoneNumber"');
      
      final appwrite = Get.find<AppwriteService>();
      
      // Utiliser directement le numéro formaté par la bibliothèque
      print('AuthController: Utilisation du numéro sans modification: "$phoneNumber"');
      
      print('AuthController: Appel à createPhoneToken avec numéro: "$phoneNumber"');
      final result = await appwrite.account.createPhoneToken(
        userId: ID.unique(),
        phone: phoneNumber
      );
      
      print('AuthController: Token créé avec succès, userId: ${result.userId}');
      return result;
    } catch (e) {
      print('AuthController: ERREUR lors de la création du token: $e');
      error.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Vérifier le code OTP reçu par SMS
  Future<void> verifyPhoneCode(String userId, String code) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final appwrite = Get.find<AppwriteService>();
      
      await appwrite.account.updatePhoneSession(
        userId: userId,
        secret: code
      );
      
      // Après la vérification, l'utilisateur est connecté
      final account = await appwrite.account.get();
      user.value = UserModel.fromAppwriteAccount(account);
      isEmailVerified.value = true; // Considéré comme vérifié avec auth SMS
      
      await DataLoadingService.loadAllData();
      Get.offAllNamed(AppRoutes.dashboard);
    } catch (e) {
      error.value = e.toString();
      throw e;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Méthodes d'authentification par email conservées pour compatibilité
  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final appwrite = Get.find<AppwriteService>();
      
      await appwrite.account.createEmailPasswordSession(
        email: email,
        password: password
      );
      
      final account = await appwrite.account.get();
      user.value = UserModel.fromAppwriteAccount(account);
      isEmailVerified.value = true; // Toujours considéré comme vérifié
      
      await DataLoadingService.loadAllData();
      Get.offAllNamed(AppRoutes.dashboard);
    } catch (e) {
      error.value = e.toString();
      throw e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final appwrite = Get.find<AppwriteService>();
      
      final account = await appwrite.account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name
      );
      
      await appwrite.account.createEmailPasswordSession(
        email: email,
        password: password
      );
      
      user.value = UserModel.fromAppwriteAccount(account);
      isEmailVerified.value = true; // Considéré comme vérifié avec auth SMS
      
      await DataLoadingService.loadAllData();
      Get.offAllNamed(AppRoutes.dashboard);
    } catch (e) {
      error.value = e.toString();
      throw e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final appwrite = Get.find<AppwriteService>();
      await appwrite.account.deleteSession(sessionId: 'current');
      
      user.value = null;
      isEmailVerified.value = false;
      
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> logout() async {
    await signOut();
  }

  void reset() {
    user.value = null;
    error.value = '';
    isEmailVerified.value = true; // Considéré comme vérifié avec auth SMS
  }
  
  Future<bool> sendVerificationEmail() async {
    try {
      final appwrite = Get.find<AppwriteService>();
      await appwrite.account.createVerification(
        url: '${dotenv.env['APP_URL'] ?? 'http://localhost:3000'}/verify'
      );
      return true;
    } catch (e) {
      error.value = e.toString();
      return false;
    }
  }
  
  Future<bool> resendVerificationEmail() async {
    try {
      await sendVerificationEmail();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> checkEmailVerification() async {
    try {
      final appwrite = Get.find<AppwriteService>();
      final account = await appwrite.account.get();
      
      isEmailVerified.value = account.emailVerification;
      return account.emailVerification;
    } catch (e) {
      return false;
    }
  }
}
