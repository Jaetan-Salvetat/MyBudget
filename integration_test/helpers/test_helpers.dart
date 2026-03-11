import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

Future<void> navigateToTab(WidgetTester tester, int index) async {
  final labels = ['Accueil', 'Comptes', 'Dépenses', 'Revenus', 'Emprunts'];
  final navItem = find.descendant(
    of: find.byType(FrostedBottomNavigationBar),
    matching: find.text(labels[index]),
  );
  await tester.tap(navItem);
  await tester.pumpAndSettle();
}

Future<void> navigateToSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings));
  await tester.pumpAndSettle();
}

Future<void> goBack(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
}

Future<void> dismissBottomSheet(WidgetTester tester) async {
  await tester.tapAt(const Offset(100, 50));
  await tester.pumpAndSettle();
}

Future<void> tapFab(WidgetTester tester) async {
  await tester.tap(find.byType(FrostedFloatingActionButton));
  await tester.pumpAndSettle();
}

Future<void> tapButton(WidgetTester tester, String text) async {
  var finder = find.text(text);
  if (finder.evaluate().isEmpty) {
    finder = find.text(text, skipOffstage: false);
  }
  final target = finder.last;
  await Scrollable.ensureVisible(target.evaluate().first, alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

Future<void> enterTextField(
  WidgetTester tester,
  String label,
  String text,
) async {
  final finder = find.widgetWithText(FrostedTextField, label);
  await tester.ensureVisible(finder);
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

Future<void> clearAndEnterTextField(
  WidgetTester tester,
  String label,
  String text,
) async {
  final finder = find.widgetWithText(FrostedTextField, label);
  await tester.ensureVisible(finder);
  await tester.enterText(finder, '');
  await tester.pumpAndSettle();
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

Future<void> enterAutocompleteField(
  WidgetTester tester,
  String label,
  String text,
) async {
  final finder = find.widgetWithText(FrostedAutocomplete<String>, label);
  await tester.ensureVisible(finder);
  final textFieldFinder = find.descendant(
    of: finder,
    matching: find.byType(TextField),
  );
  await tester.enterText(textFieldFinder, text);
  await tester.pumpAndSettle();
}

Future<void> selectDropdownValue(
  WidgetTester tester,
  Type dropdownType,
  String value,
) async {
  final dropdown = find.byType(dropdownType);
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(value).last);
  await tester.pumpAndSettle();
}

Future<void> scrollDown(WidgetTester tester, {double distance = 300}) async {
  await tester.drag(find.byType(Scrollable).last, Offset(0, -distance));
  await tester.pumpAndSettle();
}

Future<void> createAccount(
  WidgetTester tester,
  String name,
  String bank,
) async {
  await navigateToTab(tester, 1);
  await tapFab(tester);
  await enterTextField(tester, 'Nom du compte', name);
  await enterAutocompleteField(tester, 'Nom de la banque', bank);
  await tapButton(tester, 'Ajouter');
}

Future<void> createCategory(WidgetTester tester, String name) async {
  await navigateToSettings(tester);
  await tapButton(tester, 'Gérer les catégories');
  await tapButton(tester, 'Ajouter une catégorie');
  await enterTextField(tester, 'Nom de la catégorie', name);
  await tapButton(tester, 'Ajouter');
  await dismissBottomSheet(tester);
  await goBack(tester);
}

Future<void> createExpense(
  WidgetTester tester, {
  required String name,
  required String amount,
  String frequency = 'Mensuel',
}) async {
  await navigateToTab(tester, 2);
  await tapFab(tester);
  await enterTextField(tester, 'Nom', name);
  await enterTextField(tester, 'Montant', amount);
  if (frequency != 'Mensuel') {
    await tapButton(tester, frequency);
  }
  await scrollDown(tester);
  await tapButton(tester, 'Ajouter');
}

Future<void> createRevenue(
  WidgetTester tester, {
  required String name,
  required String amount,
}) async {
  await navigateToTab(tester, 3);
  await tapFab(tester);
  await enterTextField(tester, 'Nom', name);
  await enterTextField(tester, 'Montant', amount);
  await scrollDown(tester);
  await tapButton(tester, 'Ajouter');
}

Future<void> createBeneficiary(WidgetTester tester, String name) async {
  await navigateToSettings(tester);
  await tapButton(tester, 'Gérer les bénéficiaires');
  await tapButton(tester, 'Ajouter un bénéficiaire');
  await enterTextField(tester, 'Nom', name);
  await tapButton(tester, 'Ajouter');
  await dismissBottomSheet(tester);
  await goBack(tester);
}

Future<void> createAmortizableLoan(
  WidgetTester tester, {
  required String name,
  required String lender,
  required String amount,
  required String duration,
  required String rate,
}) async {
  await navigateToTab(tester, 4);
  await tapFab(tester);

  await enterTextField(tester, 'Nom du prêt', name);
  await enterTextField(tester, 'Prêteur (Banque)', lender);
  await enterTextField(tester, 'Montant emprunté', amount);
  await scrollDown(tester);
  await tapButton(tester, 'Compte de prélèvement');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Compte Test').last);
  await tester.pumpAndSettle();
  await tapButton(tester, 'Suivant');

  await tapButton(tester, 'Mois');
  await enterTextField(tester, 'Durée', duration);
  await enterTextField(tester, "Taux d'intérêt (Annuel)", rate);
  await tapButton(tester, 'Suivant');

  await tapButton(tester, 'Suivant');

  await tapButton(tester, 'Suivant');

  await tapButton(tester, 'Terminer');
}
