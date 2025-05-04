import 'package:get/get.dart';
import 'package:mybudget/core/controllers/auth_controller.dart';
import 'package:mybudget/core/services/appwrite/appwrite_privacy_service.dart';
import 'package:mybudget/data/models/privacy_settings_model.dart';

class PrivacyController extends GetxController {
  final Rx<PrivacySettingsModel> privacySettings =
      PrivacySettingsModel(
        privacyPolicyAccepted: false,
        marketingConsent: false,
        consentDate: DateTime.now(),
      ).obs;

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Écouter les changements d'utilisateur mais avec vérification complète
    ever(Get.find<AuthController>().user, (user) {
      _checkUserAndLoadPreferences();
    });
    
    // Écouter les changements d'état de vérification d'email
    ever(Get.find<AuthController>().isEmailVerified, (isVerified) {
      _checkUserAndLoadPreferences();
    });
    
    // Vérifier immédiatement l'état actuel
    _checkUserAndLoadPreferences();
  }
  
  // Méthode centrale pour gérer la vérification et le chargement
  Future<void> _checkUserAndLoadPreferences() async {
    final authController = Get.find<AuthController>();
    
    // Ne rien faire si l'utilisateur n'est pas authentifié ou son email n'est pas vérifié
    if (!authController.isAuthenticated || !authController.isEmailVerified.value) {
      return;
    }
    
    // L'utilisateur est authentifié et vérifié, on peut charger ses préférences
    getPrivacySettings();
  }

  Future<void> getPrivacySettings() async {
    try {
      final authController = Get.find<AuthController>();
      // Double vérification pour s'assurer que l'utilisateur est bien authentifié et vérifié
      if (!authController.isAuthenticated || !authController.isEmailVerified.value) {
        return;
      }
      
      isLoading.value = true;
      error.value = '';
      
      final settings = await AppwritePrivacyService.getPrivacySettings();
      if (settings != null) {
        privacySettings.value = settings;
      }
    } catch (e) {
      // Gérer silencieusement les erreurs liées aux permissions
      if (e.toString().contains('unauthorized_scope')) {
        print('Accès aux préférences ignoré - utilisateur sans permission');
      } else {
        error.value = e.toString();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> savePrivacySettings({
    required bool privacyPolicyAccepted,
    required bool marketingConsent,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final settings = PrivacySettingsModel(
        privacyPolicyAccepted: privacyPolicyAccepted,
        marketingConsent: marketingConsent,
        consentDate: DateTime.now(),
      );

      await AppwritePrivacyService.savePrivacySettings(settings);
      privacySettings.value = settings;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateMarketingConsent(bool consent) async {
    try {
      isLoading.value = true;
      error.value = '';

      await AppwritePrivacyService.updateMarketingConsent(consent);
      final updatedSettings = privacySettings.value.copyWith(
        marketingConsent: consent,
      );
      privacySettings.value = updatedSettings;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void reset() {
    privacySettings.value = PrivacySettingsModel(
      privacyPolicyAccepted: false,
      marketingConsent: false,
      consentDate: DateTime.now(),
    );
    error.value = '';
  }
}
