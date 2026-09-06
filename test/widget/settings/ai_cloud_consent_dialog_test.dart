import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/ui/settings/widgets/ai_cloud_consent_dialog.dart';

void main() {
  late Future<bool> answer;

  Future<void> showDialogFor(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.light(seedColor: const Color(0xFF2A55D3)),
        home: Builder(
          builder: (BuildContext context) {
            capturedContext = context;
            return const Scaffold();
          },
        ),
      ),
    );

    answer = AiCloudConsentDialog.show(capturedContext, AiProvider.gemini);
    await tester.pumpAndSettle();
  }

  group('AiCloudConsentDialog', () {
    testWidgets('names the service it is about to feed', (tester) async {
      await showDialogFor(tester);

      expect(
        find.text('Ce qui sera envoyé à ${AiProvider.gemini.label}'),
        findsOneWidget,
      );
    });

    testWidgets('warns that the whole receipt photo leaves the phone', (
      tester,
    ) async {
      await showDialogFor(tester);

      expect(find.text(AiCloudConsentDialog.scanWarning), findsOneWidget);
    });

    testWidgets('warns that the free plan keeps and reuses the data', (
      tester,
    ) async {
      await showDialogFor(tester);

      expect(find.text(AiCloudConsentDialog.freePlanWarning), findsOneWidget);
    });

    testWidgets('no longer promises that amounts stay on the phone', (
      tester,
    ) async {
      await showDialogFor(tester);

      expect(find.textContaining('Aucun montant'), findsNothing);
    });

    testWidgets('activating answers yes, dismissing answers no', (
      tester,
    ) async {
      await showDialogFor(tester);
      await tester.tap(find.text('Activer'));
      await tester.pumpAndSettle();

      expect(await answer, isTrue);

      await showDialogFor(tester);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(await answer, isFalse);
    });
  });
}
