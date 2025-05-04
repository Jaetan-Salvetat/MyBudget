import 'package:get/get.dart';
import 'package:mybudget/core/services/appwrite_service.dart';
import 'package:mybudget/data/models/privacy_settings_model.dart';

class PrivacyDatasource {
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  final String _privacyPreferenceKey = 'privacy_settings';
  
  Future<PrivacySettingsModel?> getPrivacySettings() async {
    try {
      final response = await _appwriteService.account.getPrefs();
      
      if (!response.data.containsKey(_privacyPreferenceKey)) {
        return null;
      }
      
      final data = response.data[_privacyPreferenceKey];
      return PrivacySettingsModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }
  
  Future<void> savePrivacySettings(PrivacySettingsModel settings) async {
    try {
      await _appwriteService.account.updatePrefs(
        prefs: {
          _privacyPreferenceKey: settings.toJson(),
        }
      );
    } catch (e) {
      throw Exception('Failed to save privacy settings: ${e.toString()}');
    }
  }
  
  Future<void> updateMarketingConsent(bool consent) async {
    try {
      final currentSettings = await getPrivacySettings();
      
      if (currentSettings == null) {
        final newSettings = PrivacySettingsModel(
          privacyPolicyAccepted: true,
          marketingConsent: consent,
          consentDate: DateTime.now()
        );
        
        await savePrivacySettings(newSettings);
        return;
      }
      
      final updatedSettings = PrivacySettingsModel(
        privacyPolicyAccepted: currentSettings.privacyPolicyAccepted,
        marketingConsent: consent,
        consentDate: DateTime.now()
      );
      await savePrivacySettings(updatedSettings);
    } catch (e) {
      throw Exception('Failed to update marketing consent: ${e.toString()}');
    }
  }
}
