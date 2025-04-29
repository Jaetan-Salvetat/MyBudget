import 'package:hive/hive.dart';
import 'package:mybudget/domain/entities/privacy_settings.dart';

part 'privacy_settings_model.g.dart';

@HiveType(typeId: 6)
class PrivacySettingsModel implements PrivacySettings {
  @HiveField(0)
  final bool _privacyPolicyAccepted;

  @HiveField(1)
  final bool _marketingConsent;

  @HiveField(2)
  final DateTime _consentDate;

  PrivacySettingsModel({
    required bool privacyPolicyAccepted,
    required bool marketingConsent,
    required DateTime consentDate,
  })  : _privacyPolicyAccepted = privacyPolicyAccepted,
        _marketingConsent = marketingConsent,
        _consentDate = consentDate;

  @override
  bool get privacyPolicyAccepted => _privacyPolicyAccepted;

  @override
  bool get marketingConsent => _marketingConsent;

  @override
  DateTime get consentDate => _consentDate;

  PrivacySettingsModel copyWith({
    bool? privacyPolicyAccepted,
    bool? marketingConsent,
    DateTime? consentDate,
  }) {
    return PrivacySettingsModel(
      privacyPolicyAccepted: privacyPolicyAccepted ?? _privacyPolicyAccepted,
      marketingConsent: marketingConsent ?? _marketingConsent,
      consentDate: consentDate ?? _consentDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'privacyPolicyAccepted': _privacyPolicyAccepted,
      'marketingConsent': _marketingConsent,
      'consentDate': _consentDate.toIso8601String(),
    };
  }

  factory PrivacySettingsModel.fromJson(Map<String, dynamic> json) {
    return PrivacySettingsModel(
      privacyPolicyAccepted: json['privacyPolicyAccepted'],
      marketingConsent: json['marketingConsent'],
      consentDate: DateTime.parse(json['consentDate']),
    );
  }
}
