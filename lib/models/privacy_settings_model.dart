class PrivacySettingsModel {
  final bool _privacyPolicyAccepted;
  final bool _marketingConsent;
  final DateTime _consentDate;

  PrivacySettingsModel({
    required bool privacyPolicyAccepted,
    required bool marketingConsent,
    required DateTime consentDate,
  }) : _privacyPolicyAccepted = privacyPolicyAccepted,
       _marketingConsent = marketingConsent,
       _consentDate = consentDate;

  bool get privacyPolicyAccepted => _privacyPolicyAccepted;

  bool get marketingConsent => _marketingConsent;

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
