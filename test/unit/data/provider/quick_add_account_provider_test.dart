import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/data/model/account_model.dart';
import 'package:mybudget/data/provider/accounts_provider.dart';
import 'package:mybudget/data/service/preferences_service.dart';
import 'package:mybudget/ui/capture/quick_add_account_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

AccountModel accountOf(int id, String name) {
  final account = AccountModel.create(name: name, bank: 'CM');
  account.id = id;
  return account;
}

class FakeAccountNotifier extends AccountNotifier {
  FakeAccountNotifier(this._accounts);

  List<AccountModel> _accounts;

  @override
  List<AccountModel> build() => _accounts;

  void emit(List<AccountModel> accounts) {
    _accounts = accounts;
    state = accounts;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAccountNotifier accounts;

  Future<void> initPreferences([Map<String, Object> stored = const {}]) async {
    SharedPreferences.setMockInitialValues(stored);
    await PreferencesService.init();
  }

  setUp(initPreferences);

  ProviderContainer makeContainer(List<AccountModel> initial) {
    accounts = FakeAccountNotifier(initial);
    final container = ProviderContainer(
      overrides: [accountProvider.overrideWith(() => accounts)],
    );
    addTearDown(container.dispose);
    container.listen(quickAddAccountProvider, (_, _) {}, fireImmediately: true);
    return container;
  }

  test('falls back to the first account', () async {
    final container = makeContainer([
      accountOf(1, 'Courant'),
      accountOf(2, 'Livret'),
    ]);
    container.read(accountProvider);

    expect(container.read(quickAddAccountProvider), 1);
  });

  test('holds no account when there is none', () async {
    final container = makeContainer([]);
    container.read(accountProvider);

    expect(container.read(quickAddAccountProvider), isNull);
  });

  test('keeps the account the user picked', () async {
    final container = makeContainer([
      accountOf(1, 'Courant'),
      accountOf(2, 'Livret'),
    ]);
    container.read(accountProvider);
    container.read(quickAddAccountProvider.notifier).select(2);

    expect(container.read(quickAddAccountProvider), 2);
  });

  test('the pick survives a refresh of the account list', () async {
    final container = makeContainer([
      accountOf(1, 'Courant'),
      accountOf(2, 'Livret'),
    ]);
    container.read(accountProvider);
    container.read(quickAddAccountProvider.notifier).select(2);

    accounts.emit([accountOf(1, 'Courant'), accountOf(2, 'Livret A')]);

    expect(container.read(quickAddAccountProvider), 2);
  });

  test('opens on the account last picked, sessions later', () async {
    await initPreferences({PreferencesService.keyQuickAddAccountId: 2});
    final container = makeContainer([
      accountOf(1, 'Courant'),
      accountOf(2, 'Livret'),
    ]);
    container.read(accountProvider);

    expect(container.read(quickAddAccountProvider), 2);
  });

  test('a pick is written down for the next session', () async {
    final container = makeContainer([
      accountOf(1, 'Courant'),
      accountOf(2, 'Livret'),
    ]);
    container.read(accountProvider);
    container.read(quickAddAccountProvider.notifier).select(2);
    await Future<void>.delayed(Duration.zero);

    expect(PreferencesService.getQuickAddAccountId(), 2);
  });

  test('a written down account that is gone is forgotten', () async {
    await initPreferences({PreferencesService.keyQuickAddAccountId: 2});
    final container = makeContainer([accountOf(1, 'Courant')]);
    container.read(accountProvider);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(quickAddAccountProvider), 1);
    expect(PreferencesService.getQuickAddAccountId(), isNull);
  });

  test('drops a pick whose account is gone', () async {
    final container = makeContainer([
      accountOf(1, 'Courant'),
      accountOf(2, 'Livret'),
    ]);
    container.read(accountProvider);
    container.read(quickAddAccountProvider.notifier).select(2);

    accounts.emit([accountOf(1, 'Courant')]);

    expect(container.read(quickAddAccountProvider), 1);
  });
}
