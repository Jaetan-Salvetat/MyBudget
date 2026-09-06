import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/scan/widgets/scan_commit_bar.dart';

import '../../helpers/scan_review_factory.dart';

AccountModel accountOf(int id, String name) =>
    AccountModel.create(name: name, bank: 'Banque')..id = id;

Future<void> pumpBar(
  WidgetTester tester, {
  int pendingCount = 0,
  double total = 14.89,
  List<AccountModel> accounts = const [],
  int? selectedAccountId,
  VoidCallback? onCommit,
  VoidCallback? onFocusPending,
}) async {
  await tester.pumpWidget(
    scanHarness(
      ScanCommitBar(
        pendingCount: pendingCount,
        total: total,
        accounts: accounts,
        selectedAccountId: selectedAccountId,
        onSelectAccount: (_) {},
        onFocusPending: onFocusPending ?? () {},
        onCommit: onCommit ?? () {},
      ),
    ),
  );
}

void main() {
  testWidgets('tant qu\'il reste à ranger, le bouton le dit', (tester) async {
    await pumpBar(tester, pendingCount: 2);

    expect(find.text(ScanCommitBar.pendingLabelOf(2)), findsOneWidget);
    expect(find.textContaining('Enregistrer'), findsNothing);
  });

  testWidgets('le bouton d\'attente renvoie vers les lignes concernées', (
    tester,
  ) async {
    var focused = 0;
    await pumpBar(tester, pendingCount: 2, onFocusPending: () => focused++);

    await tester.tap(find.text(ScanCommitBar.pendingLabelOf(2)));
    await tester.pump();

    expect(focused, 1);
  });

  testWidgets('tout rangé, le bouton enregistre et porte le total', (
    tester,
  ) async {
    await pumpBar(tester, accounts: [accountOf(1, 'Compte courant')]);

    expect(find.textContaining('Enregistrer'), findsOneWidget);
    expect(find.textContaining('14,89'), findsOneWidget);
  });

  testWidgets('enregistrer déclenche la création', (tester) async {
    var committed = 0;
    await pumpBar(
      tester,
      accounts: [accountOf(1, 'Compte courant')],
      selectedAccountId: 1,
      onCommit: () => committed++,
    );

    await tester.tap(find.textContaining('Enregistrer'));
    await tester.pump();

    expect(committed, 1);
  });

  testWidgets('un seul compte ne se choisit pas', (tester) async {
    await pumpBar(
      tester,
      accounts: [accountOf(1, 'Compte courant')],
      selectedAccountId: 1,
    );

    expect(find.textContaining('Compte courant'), findsNothing);
  });

  testWidgets('plusieurs comptes, celui retenu est nommé', (tester) async {
    await pumpBar(
      tester,
      accounts: [accountOf(1, 'Compte courant'), accountOf(2, 'Livret A')],
      selectedAccountId: 2,
    );

    expect(find.textContaining('Livret A'), findsOneWidget);
  });

  testWidgets('sans compte, on ne peut pas enregistrer', (tester) async {
    await pumpBar(tester);

    expect(find.text(ScanCommitBar.noAccountLabel), findsOneWidget);
    expect(find.textContaining('Enregistrer'), findsNothing);
  });
}
