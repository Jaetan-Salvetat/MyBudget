import 'package:mybudget/core/services/preferences_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_provider.g.dart';

@Riverpod(keepAlive: false)
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  int build() => 0; // currentPage

  void onPageChanged(int index) => state = index;

  Future<void> completeOnboarding() async {
    await PreferencesService.setNotFirstLaunch();
  }
}
