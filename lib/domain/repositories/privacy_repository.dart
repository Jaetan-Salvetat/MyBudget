import 'package:mybudget/domain/entities/privacy_settings.dart';

abstract class PrivacyRepository {
  Future<PrivacySettings?> getPrivacySettings();
  Future<void> savePrivacySettings(PrivacySettings settings);
  Future<void> updateMarketingConsent(bool consent);
}
