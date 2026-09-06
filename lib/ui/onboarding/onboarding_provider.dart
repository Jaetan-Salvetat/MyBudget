import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_provider.g.dart';

@Riverpod(keepAlive: false)
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  int build() => 0;

  void onPageChanged(int index) => state = index;

  Future<void> complete({
    required String accountName,
    required String bank,
  }) async {
    ref
        .read(accountProvider.notifier)
        .addAccount(AccountModel.create(name: accountName, bank: bank));

    await PreferencesService.setNotFirstLaunch();
  }
}
