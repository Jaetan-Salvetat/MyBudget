import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_account_provider.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_account_line.dart';
import 'package:shared_preferences/shared_preferences.dart';

AccountModel accountOf(int id, String name) {
  final account = AccountModel.create(name: name, bank: 'CM');
  account.id = id;
  return account;
}

class FakeAccountNotifier extends AccountNotifier {
  FakeAccountNotifier(this._accounts);

  final List<AccountModel> _accounts;

  @override
  Future<List<AccountModel>> build() async => _accounts;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.init();
  });

  final lineVisibility = ValueNotifier<bool>(true);
  tearDown(() => lineVisibility.value = true);
  tearDownAll(lineVisibility.dispose);

  Future<ProviderContainer> pumpLine(
    WidgetTester tester,
    List<AccountModel> accounts, {
    ValueListenable<bool>? keepLine,
  }) async {
    final container = ProviderContainer(
      overrides: [
        accountProvider.overrideWith(() => FakeAccountNotifier(accounts)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: keepLine ?? const _AlwaysVisible(),
              builder: (context, visible, _) => visible
                  ? QuickAddAccountLine(onNoAccount: () {})
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return container;
  }

  testWidgets('names the account the transaction will land on', (tester) async {
    await pumpLine(tester, [accountOf(1, 'Courant')]);

    expect(find.textContaining('Courant'), findsOneWidget);
  });

  testWidgets('picking another account closes the sheet and keeps it', (
    tester,
  ) async {
    final container = await pumpLine(tester, [
      accountOf(1, 'Courant'),
      accountOf(2, 'Livret'),
    ]);

    await tester.tap(find.textContaining('Courant'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Livret'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(container.read(quickAddAccountProvider), 2);
    expect(find.text('Compte'), findsNothing);
    expect(find.textContaining('Livret'), findsOneWidget);
  });

  testWidgets('picks even when the line left the tree behind the sheet', (
    tester,
  ) async {
    final container = await pumpLine(tester, [
      accountOf(1, 'Courant'),
      accountOf(2, 'Livret'),
    ], keepLine: lineVisibility);

    await tester.tap(find.textContaining('Courant'));
    await tester.pumpAndSettle();

    // La barre se recompose pendant que la feuille est ouverte : la ligne
    // qui l'a ouverte n'est plus montee.
    lineVisibility.value = false;
    await tester.pumpAndSettle();

    await tester.tap(find.text('Livret'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(container.read(quickAddAccountProvider), 2);
  });

  testWidgets('the accounts read as one grouped section', (tester) async {
    await pumpLine(tester, [accountOf(1, 'Courant'), accountOf(2, 'Livret')]);

    await tester.tap(find.textContaining('Courant'));
    await tester.pumpAndSettle();

    expect(find.byType(FrostedListSection), findsOneWidget);
  });

  testWidgets('a long list of accounts scrolls rather than overflowing', (
    tester,
  ) async {
    final accounts = [
      for (var id = 1; id <= 30; id++) accountOf(id, 'Compte $id'),
    ];
    final container = await pumpLine(tester, accounts);

    await tester.tap(find.textContaining('Compte 1'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final sheetList = find.byType(Scrollable).last;
    await tester.dragUntilVisible(
      find.text('Compte 30'),
      sheetList,
      const Offset(0, -200),
    );
    await tester.drag(sheetList, const Offset(0, -200));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Compte 30'));
    await tester.pumpAndSettle();

    expect(container.read(quickAddAccountProvider), 30);
  });
}

/// Une ligne qui ne disparait jamais : le cas ordinaire des autres tests.
class _AlwaysVisible extends ValueListenable<bool> {
  const _AlwaysVisible();

  @override
  bool get value => true;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
