import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mybudget/ui/stats/models/upcoming_movement.dart';
import 'package:mybudget/ui/stats/widgets/upcoming_movements_section.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('fr_FR');
  });

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders empty state when no movements', (tester) async {
    await tester.pumpWidget(
      host(const UpcomingMovementsSection(movements: [])),
    );
    expect(find.text('Aucun mouvement à venir ce mois-ci'), findsOneWidget);
  });

  testWidgets('renders movement name and amount', (tester) async {
    final movements = [
      UpcomingMovement(
        id: 'e1',
        name: 'Loyer',
        amount: 720,
        date: DateTime(2026, 5, 24),
        direction: MovementDirection.outgoing,
        icon: Icons.home,
        color: Colors.blue,
      ),
      UpcomingMovement(
        id: 'r1',
        name: 'Salaire',
        amount: 1850,
        date: DateTime(2026, 5, 28),
        direction: MovementDirection.incoming,
        icon: Icons.savings,
        color: Colors.green,
      ),
    ];

    await tester.pumpWidget(
      host(UpcomingMovementsSection(movements: movements)),
    );

    expect(find.text('Loyer'), findsOneWidget);
    expect(find.text('Salaire'), findsOneWidget);
    expect(find.text('2 ce mois'), findsOneWidget);
    expect(find.textContaining('720,00'), findsOneWidget);
    expect(find.textContaining('850,00'), findsOneWidget);
  });
}
