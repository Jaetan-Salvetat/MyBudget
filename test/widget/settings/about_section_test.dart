import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/build_flavor.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/ui/settings/widgets/sections/about_section.dart';

const String testVersion = '1.4.0';
const String testBuildNumber = '128';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('affiche la version et le numéro de build', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appVersionProvider.overrideWithValue(testVersion),
          appBuildNumberProvider.overrideWithValue(testBuildNumber),
          buildFlavorProvider.overrideWithValue(BuildFlavor.store),
        ],
        child: MaterialApp(
          theme: FrostedTheme.light(seedColor: const Color(0xFF2A55D3)),
          home: const Scaffold(body: AboutSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('$testVersion ($testBuildNumber)'), findsOneWidget);
  });
}
