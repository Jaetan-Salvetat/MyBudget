import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/ui/capture/widgets/capture_anchor.dart';

final DateTime _fixedNow = DateTime(2026, 6, 15, 9, 30);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => initializeDateFormatting('fr_FR', null));

  Future<void> pumpAnchor(
    WidgetTester tester, {
    required double remaining,
    required double monthlyRevenues,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: CaptureAnchor(
            remaining: remaining,
            monthlyRevenues: monthlyRevenues,
            onTap: () {},
            onSettings: () {},
            now: _fixedNow,
          ),
        ),
      ),
    );
  }

  testWidgets('un mois sans rien invite à déclarer le salaire', (tester) async {
    await pumpAnchor(tester, remaining: 0, monthlyRevenues: 0);
    await tester.pumpAndSettle();

    expect(find.text(CaptureAnchor.idleFigure), findsOneWidget);
    expect(find.text(CaptureAnchor.idleInvite), findsOneWidget);
    expect(find.textContaining('de revenus'), findsNothing);
  });

  testWidgets('dès qu\'un revenu existe, le chiffre reprend sa place', (
    tester,
  ) async {
    await pumpAnchor(tester, remaining: 426.91, monthlyRevenues: 1049.10);
    await tester.pumpAndSettle();

    expect(find.text(CaptureAnchor.idleFigure), findsNothing);
    expect(find.textContaining('de revenus'), findsOneWidget);
  });

  testWidgets('une dépense sans revenu montre le négatif, pas l\'invite', (
    tester,
  ) async {
    await pumpAnchor(tester, remaining: -42, monthlyRevenues: 0);
    await tester.pumpAndSettle();

    expect(find.text(CaptureAnchor.idleInvite), findsNothing);
  });
}
