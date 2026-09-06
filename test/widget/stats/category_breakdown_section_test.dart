import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/formatting/percent_formatter.dart';
import 'package:mybudget/ui/stats/models/category_slice.dart';
import 'package:mybudget/ui/stats/widgets/category_breakdown_section.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('fr_FR');
  });

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  CategorySlice slice({
    required String label,
    required double amount,
    required double share,
    String? groupKey,
  }) => CategorySlice(
    groupKey: groupKey ?? label.toLowerCase(),
    label: label,
    color: Colors.blue,
    amount: amount,
    share: share,
  );

  testWidgets('renders an empty state without categories', (tester) async {
    await tester.pumpWidget(host(const CategoryBreakdownSection(slices: [])));

    expect(find.text('Aucune dépense ce mois-ci'), findsOneWidget);
  });

  testWidgets('scopes the section to the current month', (tester) async {
    await tester.pumpWidget(
      host(
        CategoryBreakdownSection(
          slices: [slice(label: 'Logement', amount: 720, share: 1)],
        ),
      ),
    );

    expect(find.text('ce mois-ci'), findsOneWidget);
  });

  testWidgets('renders each category with its share and amount', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        CategoryBreakdownSection(
          slices: [
            slice(label: 'Logement', amount: 720, share: 0.5),
            slice(label: 'Transport', amount: 360, share: 0.25),
          ],
        ),
      ),
    );

    expect(find.text('Logement'), findsOneWidget);
    expect(find.text(PercentFormatter.formatWhole(50)), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    expect(find.text(PercentFormatter.formatWhole(25)), findsOneWidget);
  });

  testWidgets('leaves the trend arrows to the movers section', (tester) async {
    await tester.pumpWidget(
      host(
        CategoryBreakdownSection(
          slices: [slice(label: 'Logement', amount: 720, share: 1)],
        ),
      ),
    );

    expect(find.textContaining('↑'), findsNothing);
    expect(find.textContaining('↓'), findsNothing);
  });

  testWidgets('paints one stacked segment per category', (tester) async {
    await tester.pumpWidget(
      host(
        CategoryBreakdownSection(
          slices: [
            slice(label: 'Logement', amount: 720, share: 0.6),
            slice(label: 'Transport', amount: 480, share: 0.4),
          ],
        ),
      ),
    );

    final segments = find.descendant(
      of: find.byType(FrostedStackedBar),
      matching: find.byType(DecoratedBox),
    );

    expect(segments, findsNWidgets(2));
    final first = tester.getSize(segments.first);
    final second = tester.getSize(segments.at(1));
    expect(first.height, greaterThan(0));
    expect(first.width, greaterThan(second.width));
  });

  testWidgets('caps the list at maxVisible', (tester) async {
    await tester.pumpWidget(
      host(
        CategoryBreakdownSection(
          maxVisible: 1,
          slices: [
            slice(label: 'Logement', amount: 720, share: 0.5),
            slice(label: 'Transport', amount: 360, share: 0.25),
          ],
        ),
      ),
    );

    expect(find.text('Logement'), findsOneWidget);
    expect(find.text('Transport'), findsNothing);
  });

  testWidgets('reports the tapped group', (tester) async {
    String? tapped;

    await tester.pumpWidget(
      host(
        CategoryBreakdownSection(
          slices: [
            slice(
              label: 'Logement',
              amount: 720,
              share: 1,
              groupKey: 'logement',
            ),
          ],
          onCategoryTap: (groupKey) => tapped = groupKey,
        ),
      ),
    );

    await tester.tap(find.text('Logement'));

    expect(tapped, 'logement');
  });
}
