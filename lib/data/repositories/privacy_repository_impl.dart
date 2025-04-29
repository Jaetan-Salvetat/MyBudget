import 'package:hive/hive.dart';
import 'package:mybudget/data/models/privacy_settings_model.dart';
import 'package:mybudget/domain/entities/privacy_settings.dart';
import 'package:mybudget/domain/repositories/privacy_repository.dart';

class PrivacyRepositoryImpl implements PrivacyRepository {
  static const String _boxName = 'privacy_settings_box';
  static const String _privacySettingsKey = 'privacy_settings';

  @override
  Future<PrivacySettings?> getPrivacySettings() async {
    final box = await Hive.openBox<PrivacySettingsModel>(_boxName);
    final settings = box.get(_privacySettingsKey);
    return settings;
  }

  @override
  Future<void> savePrivacySettings(PrivacySettings settings) async {
    if (settings is PrivacySettingsModel) {
      final box = await Hive.openBox<PrivacySettingsModel>(_boxName);
      await box.put(_privacySettingsKey, settings);
    }
  }

  @override
  Future<void> updateMarketingConsent(bool consent) async {
    final box = await Hive.openBox<PrivacySettingsModel>(_boxName);
    final settings = box.get(_privacySettingsKey);
    
    if (settings != null) {
      final updatedSettings = settings.copyWith(marketingConsent: consent);
      await box.put(_privacySettingsKey, updatedSettings);
    }
  }
}
