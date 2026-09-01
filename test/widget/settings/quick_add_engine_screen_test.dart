import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/ui/settings/screens/api_key_screen.dart';
import 'package:mybudget/ui/settings/screens/quick_add_engine_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: FrostedTheme.light(seedColor: const Color(0xFF2A55D3)),
          home: const QuickAddEngineScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    await PreferencesService.init();
  });

  group('QuickAddEngineScreen', () {
    testWidgets('ne propose que les deux moteurs câblés', (tester) async {
      await pumpScreen(tester);

      expect(find.text(QuickAddEngineMode.onDevice.label), findsOneWidget);
      expect(find.text('Clé API personnelle'), findsOneWidget);
      expect(find.text('Gemini Nano'), findsNothing);
      expect(find.text('Recommandé'), findsNothing);
    });

    testWidgets('retient le modèle embarqué', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text(QuickAddEngineMode.onDevice.label));
      await tester.pumpAndSettle();

      expect(
        PreferencesService.getQuickAddEngineMode(),
        QuickAddEngineMode.onDevice,
      );
    });

    testWidgets('ouvre l\'écran de clé quand aucune n\'est enregistrée', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Clé API personnelle'));
      await tester.pumpAndSettle();

      expect(find.byType(ApiKeyScreen), findsOneWidget);
      expect(
        PreferencesService.getQuickAddEngineMode(),
        QuickAddEngineMode.onDevice,
      );
    });
  });
}
