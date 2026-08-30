import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

void main() {
  const Color seed = Color(0xFF2A55D3);

  const List<FrostedNavItem> destinations = <FrostedNavItem>[
    FrostedNavItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Accueil',
    ),
    FrostedNavItem(icon: Icons.swap_vert_outlined, label: 'Transactions'),
    FrostedNavItem(icon: Icons.bar_chart_outlined, label: 'Stats'),
    FrostedNavItem(icon: Icons.account_balance_outlined, label: 'Comptes'),
  ];

  Future<void> pump(
    WidgetTester tester, {
    int selectedIndex = 0,
    ValueChanged<int>? onDestinationSelected,
    List<FrostedNavItem> items = destinations,
    NavigationDestinationLabelBehavior? labelBehavior,
    EdgeInsets viewPadding = EdgeInsets.zero,
    bool folded = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.light(seedColor: seed),
        home: MediaQuery(
          data: MediaQueryData(padding: viewPadding),
          child: Scaffold(
            bottomNavigationBar: FrostedBottomBar(
              destinations: items,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected ?? (int _) {},
              labelBehavior: labelBehavior,
              folded: folded,
            ),
          ),
        ),
      ),
    );
  }

  group('FrostedBottomBar', () {
    testWidgets('renders one target per destination', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      expect(find.byIcon(Icons.dashboard), findsOneWidget);
      expect(find.byIcon(Icons.swap_vert_outlined), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart_outlined), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_outlined), findsOneWidget);
    });

    testWidgets('reports the index of the destination that was tapped', (
      WidgetTester tester,
    ) async {
      int? selected;
      await pump(tester, onDestinationSelected: (int i) => selected = i);

      await tester.tap(find.byIcon(Icons.bar_chart_outlined));
      await tester.pumpAndSettle();

      expect(selected, 2);
    });

    testWidgets('reports a tap on the destination already selected too', (
      WidgetTester tester,
    ) async {
      int? selected;
      await pump(
        tester,
        selectedIndex: 1,
        onDestinationSelected: (int i) => selected = i,
      );

      await tester.tap(find.byIcon(Icons.swap_vert_outlined));
      await tester.pumpAndSettle();

      expect(selected, 1);
    });

    testWidgets('shows the selected icon only for the selected destination', (
      WidgetTester tester,
    ) async {
      await pump(tester, selectedIndex: 0);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.dashboard), findsOneWidget);
      expect(find.byIcon(Icons.dashboard_outlined), findsNothing);

      await pump(tester, selectedIndex: 1);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.dashboard_outlined), findsOneWidget);
      expect(find.byIcon(Icons.dashboard), findsNothing);
    });

    testWidgets('every destination spells out its label', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      for (final FrostedNavItem item in destinations) {
        expect(find.text(item.label), findsOneWidget);
      }
    });

    testWidgets('the label behaviour goes straight through to M3', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).labelBehavior,
        NavigationDestinationLabelBehavior.alwaysHide,
      );
      expect(find.byIcon(Icons.dashboard), findsOneWidget);
    });

    testWidgets('hands its geometry to M3 rather than re-cutting it', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      final NavigationBar bar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );

      expect(bar.height, isNull);
      expect(bar.labelBehavior, isNull);
      expect(bar.backgroundColor, Colors.transparent);
      expect(bar.elevation, 0);
    });

    testWidgets('stands exactly as tall as the M3 bar it wears', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      final double frosted = tester
          .getSize(find.byType(FrostedBottomBar))
          .height;

      await tester.pumpWidget(
        MaterialApp(
          theme: FrostedTheme.light(seedColor: seed),
          home: Scaffold(
            bottomNavigationBar: NavigationBar(
              selectedIndex: 0,
              destinations: <Widget>[
                for (final FrostedNavItem item in destinations)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    label: item.label,
                  ),
              ],
            ),
          ),
        ),
      );

      expect(frosted, tester.getSize(find.byType(NavigationBar)).height);
    });

    testWidgets('the bar carries the bottom inset itself', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      final double flush = tester.getSize(find.byType(FrostedBottomBar)).height;

      await pump(tester, viewPadding: const EdgeInsets.only(bottom: 34));
      final double inset = tester.getSize(find.byType(FrostedBottomBar)).height;

      expect(inset, flush + 34);
    });

    testWidgets('the destinations clear the inset rather than sitting in it', (
      WidgetTester tester,
    ) async {
      await pump(tester, viewPadding: const EdgeInsets.only(bottom: 34));

      final double barBottom = tester
          .getRect(find.byType(FrostedBottomBar))
          .bottom;
      final double iconBottom = tester
          .getRect(find.byIcon(Icons.dashboard))
          .bottom;

      expect(barBottom - iconBottom, greaterThanOrEqualTo(34));
    });

    testWidgets('spans the full width of the scaffold', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      expect(
        tester.getSize(find.byType(FrostedBottomBar)).width,
        tester.getSize(find.byType(Scaffold)).width,
      );
    });

    testWidgets('gives its destinations equal room', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      final List<double> centres = <IconData>[
        Icons.dashboard,
        Icons.swap_vert_outlined,
        Icons.bar_chart_outlined,
        Icons.account_balance_outlined,
      ].map((IconData icon) => tester.getCenter(find.byIcon(icon)).dx).toList();

      final double step = centres[1] - centres[0];
      expect(centres[2] - centres[1], moreOrLessEquals(step, epsilon: 0.5));
      expect(centres[3] - centres[2], moreOrLessEquals(step, epsilon: 0.5));
    });

    testWidgets('wears the glass its own scale calls for, opened at the top', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      final FrostedGlass glass = tester.widget<FrostedGlass>(
        find.descendant(
          of: find.byType(FrostedBottomBar),
          matching: find.byType(FrostedGlass),
        ),
      );

      expect(glass.level, FrostedGlassLevel.regular);
      expect(glass.tone, FrostedGlassTone.auto);
      expect(glass.elevation, FrostedGlassElevation.none);
      expect(glass.borderRadius, BorderRadius.zero);
      expect(glass.borderEdges, <FrostedGlassEdge>{FrostedGlassEdge.top});
    });

    testWidgets('lets the glass be the surface, not the M3 container', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      final Material surface = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(NavigationBar),
              matching: find.byType(Material),
            )
            .first,
      );

      expect(surface.color, Colors.transparent);
    });

    testWidgets('carries a badge next to the destination that owns it', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        items: const <FrostedNavItem>[
          FrostedNavItem(icon: Icons.dashboard_outlined, label: 'Accueil'),
          FrostedNavItem(
            icon: Icons.swap_vert_outlined,
            label: 'Transactions',
            badge: FrostedBadge.count(3),
          ),
        ],
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('folded, the bar rolls away entirely', (
      WidgetTester tester,
    ) async {
      await pump(tester, folded: true);
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(FrostedBottomBar)).height, 0);
    });

    testWidgets('folded, the row takes no tap of its own', (
      WidgetTester tester,
    ) async {
      int? selected;
      await pump(
        tester,
        folded: true,
        onDestinationSelected: (int i) => selected = i,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byIcon(Icons.bar_chart_outlined),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(selected, isNull);
    });

    testWidgets('unfolding brings the bar back whole', (
      WidgetTester tester,
    ) async {
      await pump(tester, folded: true);
      await tester.pumpAndSettle();

      await pump(tester);
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(FrostedBottomBar)).height,
        tester.getSize(find.byType(NavigationBar)).height,
      );
    });
  });
}
