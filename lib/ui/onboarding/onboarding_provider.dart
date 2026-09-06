import 'package:mybudget/data/model/account_model.dart';
import 'package:mybudget/data/provider/accounts_provider.dart';
import 'package:mybudget/data/service/preferences_service.dart';
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
