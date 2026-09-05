import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/ui/stats/widgets/fixed_share_section.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('fr_FR');
  });

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  Widget section({
    double share = 0.31,
    double shareDelta = 0.03,
    double recurringExpenses = 1359,
    double variableExpenses = 3014,
    bool hasComparison = true,
  }) => host(
    FixedShareSection(
      share: share,
      shareDelta: shareDelta,
      recurringExpenses: recurringExpenses,
      variableExpenses: variableExpenses,
      hasComparison: hasComparison,
    ),
  );

  testWidgets('states the share and both amounts', (tester) async {
    await tester.pumpWidget(section());

    expect(find.text('31 %'), findsOneWidget);
    expect(find.textContaining('Récurrent'), findsOneWidget);
    expect(find.textContaining('Ponctuel'), findsOneWidget);
  });

  testWidgets('rounds the drift to points', (tester) async {
    await tester.pumpWidget(section(shareDelta: 0.034));

    expect(find.text('+3 pts'), findsOneWidget);
  });

  testWidgets('says stable when the share did not drift', (tester) async {
    await tester.pumpWidget(section(shareDelta: 0.001));

    expect(find.text('stable'), findsOneWidget);
  });

  testWidgets('drops the drift without a comparison', (tester) async {
    await tester.pumpWidget(section(hasComparison: false));

    expect(find.textContaining('pts'), findsNothing);
  });

  testWidgets('paints both split segments', (tester) async {
    await tester.pumpWidget(section());

    final segments = find.descendant(
      of: find.byType(FrostedStackedBar),
      matching: find.byType(DecoratedBox),
    );

    expect(segments, findsNWidgets(2));
    for (var index = 0; index < 2; index++) {
      final size = tester.getSize(segments.at(index));
      expect(size.height, greaterThan(0));
      expect(size.width, greaterThan(0));
    }
  });

  testWidgets('shows no share when nothing was spent', (tester) async {
    await tester.pumpWidget(
      section(share: 0, recurringExpenses: 0, variableExpenses: 0),
    );

    expect(find.text('0 %'), findsOneWidget);
  });
}
