import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';

const double _rowWidth = 600;
const double _hPad = FrostedSpacing.sp4;

const List<String> _scrollableLabels = <String>[
  'Overview',
  'Activity',
  'Insights',
  'Schedule',
  'Reports',
  'Settings',
];

Widget _host(FrostedTabsVariant variant, int currentIndex) {
  return MaterialApp(
    theme: FrostedTheme.dark(seedColor: Colors.deepPurple),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: _rowWidth,
          child: FrostedTabs(
            tabs: const <FrostedTab>[
              FrostedTab(label: 'Profile', icon: Icons.person_outline),
              FrostedTab(label: 'Posts', icon: Icons.article_outlined),
              FrostedTab(label: 'Photos', icon: Icons.image_outlined),
            ],
            currentIndex: currentIndex,
            onTap: (int _) {},
            variant: variant,
          ),
        ),
      ),
    ),
  );
}

Widget _scrollableHost(int currentIndex, {double width = 240}) {
  return MaterialApp(
    theme: FrostedTheme.dark(seedColor: Colors.deepPurple),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: FrostedTabs(
            tabs: <FrostedTab>[
              for (final String label in _scrollableLabels)
                FrostedTab(label: label),
            ],
            currentIndex: currentIndex,
            onTap: (int _) {},
            variant: FrostedTabsVariant.secondary,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('primary tab content is centered inside its equal-width cell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(FrostedTabsVariant.primary, 0));

    const double cellWidth = _rowWidth / 3;
    for (int i = 0; i < 3; i++) {
      final Rect label = tester.getRect(
        find.text(<String>['Profile', 'Posts', 'Photos'][i]),
      );
      final Rect icon = tester.getRect(
        find.byIcon(
          <IconData>[
            Icons.person_outline,
            Icons.article_outlined,
            Icons.image_outlined,
          ][i],
        ),
      );
      final double contentCenter = (icon.left + label.right) / 2;
      expect(
        contentCenter,
        moreOrLessEquals(cellWidth * (i + 0.5), epsilon: 1),
      );
    }
  });

  testWidgets('primary indicator is centered under the selected content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(FrostedTabsVariant.primary, 1));
    await tester.pumpAndSettle();

    final Rect label = tester.getRect(find.text('Posts'));
    final Rect icon = tester.getRect(find.byIcon(Icons.article_outlined));
    final Rect indicator = tester.getRect(
      find.byType(AnimatedPositioned).first,
    );

    expect(
      indicator.center.dx,
      moreOrLessEquals((icon.left + label.right) / 2, epsilon: 1),
    );
  });

  testWidgets('secondary tabs stay anchored to the leading edge', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(FrostedTabsVariant.secondary, 0));

    final Rect icon = tester.getRect(find.byIcon(Icons.person_outline));
    expect(icon.left, lessThan(_rowWidth / 3));
  });

  testWidgets('secondary indicator spans the full tab width', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_scrollableHost(0, width: _rowWidth));
    await tester.pumpAndSettle();

    final Rect label = tester.getRect(find.text('Overview'));
    final Rect indicator = tester.getRect(
      find.byType(AnimatedPositioned).first,
    );

    expect(indicator.left, moreOrLessEquals(label.left - _hPad, epsilon: 1));
    expect(
      indicator.width,
      moreOrLessEquals(label.width + _hPad * 2, epsilon: 1),
    );
  });

  testWidgets('secondary scrolls the newly selected tab into view', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_scrollableHost(0));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_scrollableHost(_scrollableLabels.length - 1));
    await tester.pumpAndSettle();

    final Rect tab = tester.getRect(find.text(_scrollableLabels.last));
    expect(tab.right, lessThanOrEqualTo(240));
    expect(tab.left, greaterThanOrEqualTo(0));
  });

  testWidgets('primary falls back to a scrollable row when labels cannot fit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(seedColor: Colors.deepPurple),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 180,
              child: FrostedTabs(
                tabs: <FrostedTab>[
                  for (final String label in _scrollableLabels.take(3))
                    FrostedTab(label: label, icon: Icons.person_outline),
                ],
                currentIndex: 0,
                onTap: (int _) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);

    final Rect label = tester.getRect(find.text(_scrollableLabels.first));
    final Rect icon = tester.getRect(find.byIcon(Icons.person_outline).first);
    final Rect indicator = tester.getRect(
      find.byType(AnimatedPositioned).first,
    );

    expect(indicator.left, moreOrLessEquals(icon.left, epsilon: 1));
    expect(indicator.right, moreOrLessEquals(label.right, epsilon: 1));
  });
}
