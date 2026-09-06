import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/ui/loans/screens/loan_creation_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final account = AccountModel.create(name: 'Courant', bank: 'Banque')..id = 1;

  Future<LoanModel? Function()> pushForm(WidgetTester tester) async {
    LoanModel? submitted;
    late BuildContext pageContext;

    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Builder(
            builder: (context) {
              pageContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    unawaited(
      LoanCreationScreen.push(
        context: pageContext,
        accounts: [account],
      ).then((value) => submitted = value),
    );
    await tester.pumpAndSettle();

    return () => submitted;
  }

  testWidgets('opens on the first step of the wizard', (
    WidgetTester tester,
  ) async {
    await pushForm(tester);

    expect(find.text('Nouvel emprunt bancaire'), findsOneWidget);
    expect(find.text('Nom du prêt'), findsOneWidget);
    expect(find.text('Précédent'), findsNothing);
  });

  testWidgets('keeps the next step out of reach while the form is empty', (
    WidgetTester tester,
  ) async {
    await pushForm(tester);

    await tester.ensureVisible(find.text('Suivant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();

    expect(find.text('Précédent'), findsNothing);
  });

  testWidgets('pops nothing when the user backs out', (
    WidgetTester tester,
  ) async {
    final submitted = await pushForm(tester);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(submitted(), isNull);
    expect(find.byType(LoanCreationScreen), findsNothing);
  });
}
