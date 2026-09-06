import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/accounts/screens/account_form_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AccountModel? Function()> pushForm(
    WidgetTester tester, {
    AccountModel? account,
  }) async {
    AccountModel? submitted;
    late BuildContext pageContext;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Builder(
          builder: (context) {
            pageContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    unawaited(
      AccountFormScreen.push(
        context: pageContext,
        account: account,
      ).then((value) => submitted = value),
    );
    await tester.pumpAndSettle();

    return () => submitted;
  }

  testWidgets('keeps the submit button disabled until both fields are filled', (
    WidgetTester tester,
  ) async {
    final submitted = await pushForm(tester);

    await tester.enterText(find.byType(TextField).first, 'Courant');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();

    expect(submitted(), isNull);
    expect(find.byType(AccountFormScreen), findsOneWidget);
  });

  testWidgets('pops the created account back to the caller', (
    WidgetTester tester,
  ) async {
    final submitted = await pushForm(tester);

    await tester.enterText(find.byType(TextField).first, 'Courant');
    await tester.enterText(find.byType(TextField).last, 'Banque Populaire');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();

    expect(submitted()?.name, 'Courant');
    expect(submitted()?.bank, 'Banque Populaire');
    expect(find.byType(AccountFormScreen), findsNothing);
  });

  testWidgets('keeps the edited account id when saving', (
    WidgetTester tester,
  ) async {
    final account = AccountModel.create(name: 'Courant', bank: 'Banque')
      ..id = 3;
    final submitted = await pushForm(tester, account: account);

    await tester.enterText(find.byType(TextField).first, 'Livret A');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(submitted()?.id, 3);
    expect(submitted()?.name, 'Livret A');
  });

  testWidgets('pops nothing when the user backs out', (
    WidgetTester tester,
  ) async {
    final submitted = await pushForm(tester);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(submitted(), isNull);
    expect(find.byType(AccountFormScreen), findsNothing);
  });
}
