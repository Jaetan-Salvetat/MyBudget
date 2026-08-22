import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';
import 'package:mybudget/ui/settings/widgets/sections/ai_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> initPreferences(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    await PreferencesService.init();
  }

  Widget createWidgetUnderTest() {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: AiSection()),
      ),
    );
  }

  testWidgets('renders the section title and the quick add tile', (
    tester,
  ) async {
    await initPreferences({});

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Intelligence artificielle'), findsOneWidget);
    expect(find.text('Ajout rapide'), findsOneWidget);
    expect(find.byType(FrostedSwitch), findsOneWidget);
  });

  testWidgets('switch is on when quick add is enabled', (tester) async {
    await initPreferences({});

    await tester.pumpWidget(createWidgetUnderTest());

    expect(
      tester.widget<FrostedSwitch>(find.byType(FrostedSwitch)).value,
      isTrue,
    );
  });

  testWidgets('switch is off when quick add is disabled', (tester) async {
    await initPreferences({PreferencesService.keyQuickAddEnabled: false});

    await tester.pumpWidget(createWidgetUnderTest());

    expect(
      tester.widget<FrostedSwitch>(find.byType(FrostedSwitch)).value,
      isFalse,
    );
  });

  testWidgets('tapping the switch disables quick add', (tester) async {
    await initPreferences({});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.tap(find.byType(FrostedSwitch));
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(AiSection));
    final container = ProviderScope.containerOf(element);

    expect(container.read(quickAddEnabledProvider), isFalse);
    expect(
      tester.widget<FrostedSwitch>(find.byType(FrostedSwitch)).value,
      isFalse,
    );
  });
}
