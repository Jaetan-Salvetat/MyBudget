import 'package:get/get.dart';

class PrivacyController extends GetxController {


  Future<void> getPrivacySettings() async {}

  Future<void> savePrivacySettings({
    required bool privacyPolicyAccepted,
    required bool marketingConsent,
  }) async {}

  Future<void> updateMarketingConsent(bool consent) async {}

  void reset() {}
}
