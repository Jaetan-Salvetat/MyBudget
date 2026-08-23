import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/enums/ai_model.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';
import 'package:mybudget/ui/settings/screens/ai_model_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  Future<void> pumpScreen(WidgetTester tester) async {
    container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: FrostedTheme.light(seedColor: const Color(0xFF2A55D3)),
          home: const AiModelScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.init();
  });

  group('AiModelScreen', () {
    testWidgets('lists every model of the selected provider', (tester) async {
      await pumpScreen(tester);

      for (final model in AiModel.values) {
        expect(find.text(model.label), findsOneWidget);
      }
    });

    testWidgets('tapping a model selects it', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text(AiModel.flash37.label));
      await tester.pumpAndSettle();

      expect(container.read(selectedAiModelProvider), AiModel.flash37);
    });

    testWidgets('the selection is persisted', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text(AiModel.flash35.label));
      await tester.pumpAndSettle();

      expect(PreferencesService.getAiModel(), AiModel.flash35);
    });
  });
}
