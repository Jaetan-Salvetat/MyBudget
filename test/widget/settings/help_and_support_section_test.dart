import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/ui/settings/screens/labs_screen.dart';
import 'package:mybudget/ui/settings/widgets/sections/help_and_support_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String testBuildNumber = '42';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.init();
  });

  testWidgets('ouvre le Labo depuis l\'aide et support', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appBuildNumberProvider.overrideWithValue(testBuildNumber)],
        child: MaterialApp(
          theme: FrostedTheme.light(seedColor: const Color(0xFF2A55D3)),
          home: const Scaffold(body: HelpAndSupportSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(LabsScreen.title), findsOneWidget);

    await tester.tap(find.text(LabsScreen.title));
    await tester.pumpAndSettle();

    expect(find.byType(LabsScreen), findsOneWidget);
  });
}
