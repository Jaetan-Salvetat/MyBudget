import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/data/model/account_model.dart';
import 'package:mybudget/data/provider/accounts_provider.dart';

import 'harness/e2e_harness.dart';

void main() {
  test('accountProvider se lit sans écouteur', () async {
    final E2EHarness app = await E2EHarness.start();
    addTearDown(app.dispose);

    app.accounts.add(AccountModel.create(name: 'Courant', bank: 'Boursorama'));

    expect(app.container.read(accountProvider), hasLength(1));
  });
}
