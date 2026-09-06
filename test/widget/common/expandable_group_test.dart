import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/ui/common/widgets/expandable_group.dart';

void main() {
  Future<void> pumpGroup(WidgetTester tester, {required bool expanded}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpandableGroup(
            expanded: expanded,
            header: const Text('En-tête'),
            children: const [Text('Enfant')],
          ),
        ),
      ),
    );
  }

  testWidgets('a collapsed group does not build its children', (tester) async {
    await pumpGroup(tester, expanded: false);

    expect(find.text('En-tête'), findsOneWidget);
    expect(find.text('Enfant'), findsNothing);
  });

  testWidgets('opening grows the children to their full height', (
    tester,
  ) async {
    await pumpGroup(tester, expanded: false);
    await pumpGroup(tester, expanded: true);
    await tester.pump();

    final opening = tester.getSize(find.byType(ExpandableGroup)).height;

    await tester.pumpAndSettle();
    final opened = tester.getSize(find.byType(ExpandableGroup)).height;

    expect(opening, lessThan(opened));
    expect(find.text('Enfant'), findsOneWidget);
  });

  testWidgets('closing keeps the children until the animation ends', (
    tester,
  ) async {
    await pumpGroup(tester, expanded: true);
    await tester.pumpAndSettle();

    await pumpGroup(tester, expanded: false);
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.text('Enfant'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Enfant'), findsNothing);
  });
}
