import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_account_provider.dart';

AccountModel accountOf(int id, String name) {
  final account = AccountModel.create(name: name, bank: 'CM');
  account.id = id;
  return account;
}

/// Stands in for the real account list, which pulls the whole persistence
/// graph behind it.
class FakeAccountNotifier extends AccountNotifier {
  FakeAccountNotifier(this._accounts);

  List<AccountModel> _accounts;

  @override
  Future<List<AccountModel>> build() async => _accounts;

  void emit(List<AccountModel> accounts) {
    _accounts = accounts;
    state = AsyncData(accounts);
  }
}

void main() {
  late FakeAccountNotifier accounts;

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
    await container.read(accountProvider.future);

    expect(container.read(quickAddAccountProvider), 1);
  });

  test('holds no account when there is none', () async {
    final container = makeContainer([]);
    await container.read(accountProvider.future);

    expect(container.read(quickAddAccountProvider), isNull);
  });

  test('keeps the account the user picked', () async {
    final container = makeContainer([
      accountOf(1, 'Courant'),
      accountOf(2, 'Livret'),
    ]);
    await container.read(accountProvider.future);
    container.read(quickAddAccountProvider.notifier).select(2);

    expect(container.read(quickAddAccountProvider), 2);
  });

  test('the pick survives a refresh of the account list', () async {
    final container = makeContainer([
      accountOf(1, 'Courant'),
      accountOf(2, 'Livret'),
    ]);
    await container.read(accountProvider.future);
    container.read(quickAddAccountProvider.notifier).select(2);

    accounts.emit([accountOf(1, 'Courant'), accountOf(2, 'Livret A')]);

    expect(container.read(quickAddAccountProvider), 2);
  });

  test('drops a pick whose account is gone', () async {
    final container = makeContainer([
      accountOf(1, 'Courant'),
      accountOf(2, 'Livret'),
    ]);
    await container.read(accountProvider.future);
    container.read(quickAddAccountProvider.notifier).select(2);

    accounts.emit([accountOf(1, 'Courant')]);

    expect(container.read(quickAddAccountProvider), 1);
  });
}
