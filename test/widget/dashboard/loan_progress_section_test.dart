import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mybudget/ui/dashboard/models/loan_progress_summary.dart';
import 'package:mybudget/ui/dashboard/widgets/loan_progress_section.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('fr_FR');
  });

  LoanProgressEntry entry(int id, String name) => LoanProgressEntry(
    id: id,
    name: name,
    remainingCapital: 4000,
    monthlyPayment: 250,
    remainingMonths: 18,
  );

  LoanProgressSummary summaryWith(List<LoanProgressEntry> loans) =>
      LoanProgressSummary(
        totalBorrowed: 10000,
        totalRepaid: 5000,
        totalRemaining: 5000,
        monthlyPayments: 500,
        activeCount: loans.length,
        progressPercent: 0.5,
        loans: loans,
      );

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders nothing without loans', (tester) async {
    await tester.pumpWidget(
      host(LoanProgressSection(summary: summaryWith(const []))),
    );

    expect(find.text('Emprunts'), findsNothing);
  });

  testWidgets('renders the amortised capital progress', (tester) async {
    await tester.pumpWidget(
      host(
        LoanProgressSection(
          summary: summaryWith([entry(1, 'Prêt auto'), entry(2, 'Prêt conso')]),
        ),
      ),
    );

    expect(find.text('Capital amorti'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('2 actifs'), findsOneWidget);
  });

  testWidgets('lists every loan', (tester) async {
    await tester.pumpWidget(
      host(
        LoanProgressSection(
          summary: summaryWith([entry(1, 'Prêt auto'), entry(2, 'Prêt conso')]),
        ),
      ),
    );

    expect(find.text('Prêt auto'), findsOneWidget);
    expect(find.text('Prêt conso'), findsOneWidget);
  });

  testWidgets('caps the visible loans and offers the rest', (tester) async {
    await tester.pumpWidget(
      host(
        LoanProgressSection(
          summary: summaryWith([
            entry(1, 'Prêt auto'),
            entry(2, 'Prêt conso'),
            entry(3, 'Prêt travaux'),
            entry(4, 'Prêt immo'),
          ]),
        ),
      ),
    );

    expect(find.text('Prêt immo'), findsNothing);
    expect(find.text('1 autre emprunt'), findsOneWidget);
  });

  testWidgets('invokes onSummaryTap when the aggregate is tapped', (
    tester,
  ) async {
    var tapped = 0;

    await tester.pumpWidget(
      host(
        LoanProgressSection(
          summary: summaryWith([entry(1, 'Prêt auto')]),
          onSummaryTap: () => tapped++,
        ),
      ),
    );

    await tester.tap(find.text('Capital amorti'));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets('invokes onLoanTap with the tapped loan id', (tester) async {
    int? tappedId;

    await tester.pumpWidget(
      host(
        LoanProgressSection(
          summary: summaryWith([entry(1, 'Prêt auto'), entry(2, 'Prêt conso')]),
          onLoanTap: (id) => tappedId = id,
        ),
      ),
    );

    await tester.tap(find.text('Prêt conso'));
    await tester.pump();

    expect(tappedId, 2);
  });
}
