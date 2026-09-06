import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/data/model/account_model.dart';
import 'package:mybudget/data/service/preferences_service.dart';
import 'package:mybudget/ui/home/home_screen.dart';
import 'package:mybudget/ui/onboarding/onboarding_page.dart';
import 'package:mybudget/ui/onboarding/onboarding_provider.dart';
import 'package:mybudget/ui/splash/splash_screen.dart';

import 'harness/e2e_harness.dart';

void main() {
  late E2EHarness app;

  final DateTime now = E2EHarness.defaultNow;

  setUp(() async {
    app = await E2EHarness.start(now: now);
  });

  tearDown(() => app.dispose());

  Future<void> pumpOnboarding(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: app.container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const OnboardingPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillAccount(
    WidgetTester tester, {
    String name = 'Courant',
    String bank = 'Boursorama',
  }) async {
    final Finder fields = find.byType(EditableText);
    await tester.enterText(fields.at(1), bank);
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(0), name);
    await tester.pumpAndSettle();
  }

  Future<void> goToAccountSlide(WidgetTester tester) async {
    for (int i = 0; i < OnboardingPage.accountSlide; i++) {
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
    }
  }

  group('le tout premier lancement', () {
    test('mène à l\'onboarding', () {
      expect(PreferencesService.isFirstLaunch(), isTrue);
      expect(SplashScreen.destination(), isA<OnboardingPage>());
    });

    test('une fois passé, mène à l\'accueil', () async {
      await PreferencesService.setNotFirstLaunch();

      expect(PreferencesService.isFirstLaunch(), isFalse);
      expect(SplashScreen.destination(), isA<HomeScreen>());
    });
  });

  group('le parcours d\'accueil', () {
    testWidgets('avance de diapositive en diapositive', (
      WidgetTester tester,
    ) async {
      await pumpOnboarding(tester);

      expect(app.container.read(onboardingProvider), 0);

      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      expect(app.container.read(onboardingProvider), 1);
    });

    testWidgets('finit sur la création du premier compte', (
      WidgetTester tester,
    ) async {
      await pumpOnboarding(tester);

      await goToAccountSlide(tester);

      expect(find.text('Commencer'), findsOneWidget);
      expect(find.byType(FrostedTextField), findsOneWidget);
      expect(find.byType(FrostedAutocomplete), findsOneWidget);
    });

    testWidgets('crée le compte et ouvre l\'accueil', (
      WidgetTester tester,
    ) async {
      await pumpOnboarding(tester);
      await goToAccountSlide(tester);

      await fillAccount(tester);
      await tester.runAsync(() => tester.tap(find.text('Commencer')));
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();

      final AccountModel created = app.accounts.getAll().single;
      expect(created.name, 'Courant');
      expect(created.bank, 'Boursorama');
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('retient que le premier lancement est passé', (
      WidgetTester tester,
    ) async {
      await pumpOnboarding(tester);
      await goToAccountSlide(tester);

      await fillAccount(tester);
      await tester.runAsync(() => tester.tap(find.text('Commencer')));
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();

      expect(PreferencesService.isFirstLaunch(), isFalse);
    });

    testWidgets('un compte sans banque ne peut pas être créé', (
      WidgetTester tester,
    ) async {
      await pumpOnboarding(tester);
      await goToAccountSlide(tester);

      await fillAccount(tester, bank: '   ');
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();

      expect(app.accounts.getAll(), isEmpty);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('un compte sans nom ne peut pas être créé', (
      WidgetTester tester,
    ) async {
      await pumpOnboarding(tester);
      await goToAccountSlide(tester);

      await fillAccount(tester, name: '   ');
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();

      expect(app.accounts.getAll(), isEmpty);
    });
  });
}
