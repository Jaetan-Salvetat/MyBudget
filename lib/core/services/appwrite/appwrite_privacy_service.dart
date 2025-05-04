import 'package:appwrite/appwrite.dart';
import 'package:mybudget/core/services/appwrite/appwrite_client_service.dart';
import 'package:mybudget/data/models/privacy_settings_model.dart';

class AppwritePrivacyService {
  static const String _privacySettingsKey = 'privacy_settings';
  
  static Future<PrivacySettingsModel?> getPrivacySettings() async {
    try {
      // Utilisation de preferences pour stocker les paramètres de confidentialité
      final userPreferences = await AppwriteClientService.getPreferences();
      
      if (userPreferences.containsKey(_privacySettingsKey)) {
        return PrivacySettingsModel.fromJson(
          userPreferences[_privacySettingsKey]
        );
      }
      
      return null;
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Future<void> savePrivacySettings(PrivacySettingsModel settings) async {
    try {
      final userPreferences = await AppwriteClientService.getPreferences();
      userPreferences[_privacySettingsKey] = settings.toJson();
      
      await AppwriteClientService.updatePreferences(userPreferences);
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Future<void> updateMarketingConsent(bool consent) async {
    try {
      final userPreferences = await AppwriteClientService.getPreferences();
      
      PrivacySettingsModel settings;
      if (userPreferences.containsKey(_privacySettingsKey)) {
        settings = PrivacySettingsModel.fromJson(
          userPreferences[_privacySettingsKey]
        ).copyWith(marketingConsent: consent);
      } else {
        settings = PrivacySettingsModel(
          privacyPolicyAccepted: false,
          marketingConsent: consent,
          consentDate: DateTime.now()
        );
      }
      
      userPreferences[_privacySettingsKey] = settings.toJson();
      await AppwriteClientService.updatePreferences(userPreferences);
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Exception _handleDatabaseException(dynamic e) {
    if (e is AppwriteException) {
      switch (e.code) {
        case 404:
          return Exception('Paramètres de confidentialité non trouvés');
        default:
          return Exception('Erreur de base de données: ${e.message}');
      }
    }
    return Exception('Erreur inconnue: $e');
  }
}
