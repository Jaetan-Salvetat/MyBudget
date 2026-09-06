import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/accounts/accounts_screen.dart';
import 'package:mybudget/ui/capture/capture_screen.dart';
import 'package:mybudget/ui/capture/widgets/capture_anchor.dart';
import 'package:mybudget/ui/capture/widgets/journal_view.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/home/home_navigation_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_bar.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/stats/stats_screen.dart';
import 'package:mybudget/ui/transactions/transactions_screen.dart';

import 'harness/e2e_harness.dart';
import 'harness/fake_quick_add_engine.dart';

void main() {
  late E2EHarness app;
  late int accountId;

  final DateTime now = E2EHarness.defaultNow;

  setUp(() async {
    app = await E2EHarness.start(now: now);
    accountId = app.accounts.add(
      AccountModel.create(name: 'Courant', bank: 'Boursorama'),
    );
  });

  tearDown(() => app.dispose());

  Future<void> seedSalary() {
    return app.container
        .read(revenueProvider.notifier)
        .addRevenue(
          RevenueModel.create(
            name: 'Salaire',
            amount: 2400,
            startDate: DateTime(2026, 6, 3),
            frequency: Frequency.monthly,
            accountId: accountId,
            categorySlug: 'salaire.salaire_net',
          ),
        );
  }

  group('la coquille de navigation', () {
    testWidgets('ouvre sur la saisie', (WidgetTester tester) async {
      await app.pumpHome(tester);

      expect(find.byType(CaptureScreen), findsOneWidget);
      expect(find.byType(QuickAddBar), findsOneWidget);
      expect(find.byType(JournalView), findsOneWidget);
    });

    testWidgets('mène à chaque onglet', (WidgetTester tester) async {
      await app.pumpHome(tester);

      await app.goToTab(tester, HomeTab.transactions);
      expect(find.byType(TransactionsScreen), findsOneWidget);

      await app.goToTab(tester, HomeTab.stats);
      expect(find.byType(StatsScreen), findsOneWidget);

      await app.goToTab(tester, HomeTab.accounts);
      expect(find.byType(AccountsScreen), findsOneWidget);
    });

    testWidgets('le retour ramène à la saisie', (WidgetTester tester) async {
      await app.pumpHome(tester);
      await app.goToTab(tester, HomeTab.stats);

      final bool handled = app.container
          .read(homeNavigationProvider.notifier)
          .handleBack();
      await tester.pumpAndSettle();

      expect(handled, isTrue);
      expect(find.byType(CaptureScreen), findsOneWidget);
    });

    testWidgets('depuis la saisie, le retour sort de l\'app', (
      WidgetTester tester,
    ) async {
      await app.pumpHome(tester);

      expect(
        app.container.read(homeNavigationProvider.notifier).handleBack(),
        isFalse,
      );
    });
  });

  group('l\'ancre du mois', () {
    testWidgets('affiche ce qu\'il reste et les revenus du mois', (
      WidgetTester tester,
    ) async {
      await seedSalary();
      await app.container
          .read(expenseProvider.notifier)
          .addExpense(
            ExpenseModel.create(
              name: 'Loyer',
              amount: 900,
              categorySlug: 'logement.loyer',
              startDate: DateTime(2026, 6, 5),
              frequency: Frequency.monthly,
              accountId: accountId,
            ),
          );

      await app.pumpHome(tester);

      final CaptureAnchor anchor = tester.widget<CaptureAnchor>(
        find.byType(CaptureAnchor),
      );

      expect(anchor.remaining, 1500);
      expect(anchor.monthlyRevenues, 2400);
      expect(anchor.now, now);
    });

    testWidgets('reste muette quand rien n\'est saisi', (
      WidgetTester tester,
    ) async {
      await app.pumpHome(tester);

      expect(find.text(CaptureAnchor.idleFigure), findsOneWidget);
    });
  });

  group('la saisie au doigt', () {
    testWidgets('une phrase tapée devient une dépense visible au journal', (
      WidgetTester tester,
    ) async {
      app.engine.script(
        'café 3€',
        const ScriptedClassification(
          categorySlug: 'restauration.cafe',
          name: 'Café',
          amount: 3,
        ),
      );
      await seedSalary();
      await app.pumpHome(tester);

      await tester.enterText(find.byType(FrostedTextField), 'café 3€');
      await tester.pumpAndSettle();

      expect(app.container.read(quickAddProvider).name, 'Café');

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(app.expenses.getAll().single.name, 'Café');
      expect(
        find.descendant(
          of: find.byType(JournalView),
          matching: find.text('Café'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('la dépense envoyée entame le reste du mois', (
      WidgetTester tester,
    ) async {
      app.engine.script(
        'café 3€',
        const ScriptedClassification(
          categorySlug: 'restauration.cafe',
          name: 'Café',
          amount: 3,
        ),
      );
      await seedSalary();
      await app.pumpHome(tester);

      await tester.enterText(find.byType(FrostedTextField), 'café 3€');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final CaptureAnchor anchor = tester.widget<CaptureAnchor>(
        find.byType(CaptureAnchor),
      );

      expect(anchor.remaining, 2397);
    });

    testWidgets('le champ se vide après l\'envoi', (WidgetTester tester) async {
      app.engine.script(
        'café 3€',
        const ScriptedClassification(
          categorySlug: 'restauration.cafe',
          name: 'Café',
          amount: 3,
        ),
      );
      await app.pumpHome(tester);

      await tester.enterText(find.byType(FrostedTextField), 'café 3€');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(app.container.read(quickAddProvider).isEmpty, isTrue);
    });
  });

  group('l\'écran des comptes', () {
    testWidgets('montre le compte et son solde', (WidgetTester tester) async {
      await seedSalary();

      await app.pumpHome(tester);
      await app.goToTab(tester, HomeTab.accounts);

      expect(find.text('Courant'), findsWidgets);
      expect(find.text('+ ${MoneyFormatter.format(2400)}'), findsOneWidget);
    });
  });
}
