import 'package:mybudget/data/datasources/privacy_datasource.dart';
import 'package:mybudget/data/models/privacy_settings_model.dart';
import 'package:mybudget/domain/entities/privacy_settings.dart';
import 'package:mybudget/domain/repositories/privacy_repository.dart';

class PrivacyRepositoryImpl implements PrivacyRepository {
  final PrivacyDatasource _privacyDatasource;

  PrivacyRepositoryImpl() : _privacyDatasource = PrivacyDatasource();

  @override
  Future<PrivacySettings?> getPrivacySettings() async {
    return await _privacyDatasource.getPrivacySettings();
  }

  @override
  Future<void> savePrivacySettings(PrivacySettings settings) async {
    if (settings is PrivacySettingsModel) {
      await _privacyDatasource.savePrivacySettings(settings);
    } else {
      final settingsModel = PrivacySettingsModel(
        privacyPolicyAccepted: settings.privacyPolicyAccepted,
        marketingConsent: settings.marketingConsent,
        consentDate: settings.consentDate
      );
      await _privacyDatasource.savePrivacySettings(settingsModel);
    }
  }

  @override
  Future<void> updateMarketingConsent(bool consent) async {
    await _privacyDatasource.updateMarketingConsent(consent);
  }
}
