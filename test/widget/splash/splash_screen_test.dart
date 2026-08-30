import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/ui/quick_add/quick_add_engine_provider.dart';
import 'package:mybudget/ui/splash/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.init();
  });

  Future<void> pumpSplash(WidgetTester tester, Completer<void> warmUp) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          quickAddWarmUpProvider.overrideWith((ref) => warmUp.future),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SplashScreen(),
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
}
