import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/data/models/privacy_settings_model.dart';
import 'package:mybudget/data/repositories/privacy_repository_impl.dart';
import 'package:mybudget/domain/entities/privacy_settings.dart';
import 'package:mybudget/domain/repositories/privacy_repository.dart';

final privacyRepositoryProvider = Provider<PrivacyRepository>((ref) {
  return PrivacyRepositoryImpl();
});

final privacySettingsProvider = StateNotifierProvider<PrivacySettingsNotifier, AsyncValue<PrivacySettings?>>((ref) {
  final repository = ref.watch(privacyRepositoryProvider);
  return PrivacySettingsNotifier(repository);
});

class PrivacySettingsNotifier extends StateNotifier<AsyncValue<PrivacySettings?>> {
  final PrivacyRepository _repository;

  PrivacySettingsNotifier(this._repository) : super(const AsyncLoading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _repository.getPrivacySettings();
      state = AsyncData(settings);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> savePrivacySettings({
    required bool privacyPolicyAccepted,
    required bool marketingConsent,
  }) async {
    try {
      state = const AsyncLoading();
      final settings = PrivacySettingsModel(
        privacyPolicyAccepted: privacyPolicyAccepted,
        marketingConsent: marketingConsent,
        consentDate: DateTime.now(),
      );
      await _repository.savePrivacySettings(settings);
      state = AsyncData(settings);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> updateMarketingConsent(bool consent) async {
    try {
      final currentSettings = state.value;
      if (currentSettings == null) return;
      
      state = const AsyncLoading();
      await _repository.updateMarketingConsent(consent);
      
      if (currentSettings is PrivacySettingsModel) {
        final updatedSettings = currentSettings.copyWith(
          marketingConsent: consent,
        );
        state = AsyncData(updatedSettings);
      }
      
      await _loadSettings();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}
