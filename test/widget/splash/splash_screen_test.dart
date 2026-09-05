import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/ui/home/home_screen.dart';
import 'package:mybudget/ui/onboarding/onboarding_page.dart';
import 'package:mybudget/ui/quick_add/quick_add_engine_provider.dart';
import 'package:mybudget/ui/splash/splash_screen.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

void main() {
  late MockCategoryOverrideRepository overrideRepository;
  late CategoryTaxonomyService taxonomy;

  setUpAll(() async {
    taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.init();

    overrideRepository = MockCategoryOverrideRepository();
    when(() => overrideRepository.getAll()).thenReturn({});
  });

  Future<void> pumpSplash(WidgetTester tester, Completer<void> warmUp) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          quickAddWarmUpProvider.overrideWith((ref) => warmUp.future),
          categoryOverrideRepositoryProvider.overrideWithValue(
            overrideRepository,
          ),
          categoryTaxonomyProvider.overrideWith((ref) async => taxonomy),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SplashScreen(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      ),
    );
  }

  testWidgets('waits for the warm-up, not for a clock', (tester) async {
    final warmUp = Completer<void>();
    await pumpSplash(tester, warmUp);

    await tester.pump(const Duration(seconds: 5));
    expect(find.byType(SplashScreen), findsOneWidget);

    warmUp.complete();
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('leaves as soon as the entrance and the warm-up are done', (
    tester,
  ) async {
    final warmUp = Completer<void>()..complete();
    await pumpSplash(tester, warmUp);

    await tester.pump(SplashScreen.entranceDuration);
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('never leaves before its entrance has played', (tester) async {
    final warmUp = Completer<void>()..complete();
    await pumpSplash(tester, warmUp);

    await tester.pump(SplashScreen.entranceDuration * 0.5);
    expect(find.byType(SplashScreen), findsOneWidget);
  });

  testWidgets('la toute première ouverture mène à l\'onboarding', (
    tester,
  ) async {
    final warmUp = Completer<void>()..complete();
    await pumpSplash(tester, warmUp);

    await tester.pumpAndSettle();

    expect(find.byType(OnboardingPage), findsOneWidget);
  });

  test('la destination dépend du tout premier lancement', () async {
    expect(SplashScreen.destination(), isA<OnboardingPage>());

    await PreferencesService.setNotFirstLaunch();

    expect(SplashScreen.destination(), isA<HomeScreen>());
  });
}
