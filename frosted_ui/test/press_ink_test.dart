import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

/// One tappable component, and where to press it.
class _Case {
  const _Case(this.name, this.build, this.target);

  final String name;
  final Widget Function() build;

  /// The element the press lands on — the whole component for a single
  /// target, one row or segment for the collections.
  final Finder Function() target;
}

void main() {
  const Color seed = Color(0xFF7C5CFF);

  const List<FrostedNavItem> navItems = <FrostedNavItem>[
    FrostedNavItem(icon: Icons.home, label: 'Accueil'),
    FrostedNavItem(icon: Icons.pie_chart, label: 'Budget'),
  ];

  final List<_Case> cases = <_Case>[
    _Case(
      'FrostedButton',
      () => FrostedButton.filled(label: 'Valider', onPressed: () {}),
      () => find.byType(FrostedButton),
    ),
    _Case(
      'FrostedIconButton',
      () => FrostedIconButton.filled(icon: Icons.add, onPressed: () {}),
      () => find.byType(FrostedIconButton),
    ),
    _Case(
      'FrostedFab',
      () => FrostedFab.regular(icon: Icons.add, onPressed: () {}),
      () => find.byType(FrostedFab),
    ),
    _Case(
      'FrostedChip',
      () => FrostedChip.assist(label: 'Filtrer', onTap: () {}),
      () => find.byType(FrostedChip),
    ),
    _Case(
      'FrostedCheckbox',
      () => FrostedCheckbox(value: false, onChanged: (bool? _) {}),
      () => find.byType(FrostedCheckbox),
    ),
    _Case(
      'FrostedRadio',
      () => FrostedRadio<int>(value: 1, groupValue: 0, onChanged: (int? _) {}),
      () => find.byType(FrostedRadio<int>),
    ),
    _Case(
      'FrostedSwitch',
      () => FrostedSwitch(value: false, onChanged: (bool _) {}),
      () => find.byType(FrostedSwitch),
    ),
    _Case(
      'FrostedToggleButtons',
      () => FrostedToggleButtons.connected(
        items: const <FrostedToggleItem>[
          FrostedToggleItem(icon: Icons.format_bold, label: 'Gras'),
          FrostedToggleItem(icon: Icons.format_italic, label: 'Italique'),
        ],
        selected: const <int>{0},
        onChanged: (Set<int> _) {},
      ),
      () => find.text('Italique'),
    ),
    _Case(
      'FrostedCard',
      () => FrostedCard(onTap: () {}, child: const Text('Solde')),
      () => find.byType(FrostedCard),
    ),
    _Case(
      'FrostedListTile',
      () => FrostedListTile(title: 'Courses', onTap: () {}),
      () => find.byType(FrostedListTile),
    ),
    _Case(
      'FrostedExpansionTile',
      () => const FrostedExpansionTile(
        title: 'Détails',
        child: Text('Contenu'),
      ),
      () => find.text('Détails'),
    ),
    _Case(
      'FrostedTabs',
      () => FrostedTabs(
        tabs: const <FrostedTab>[
          FrostedTab(label: 'Mois'),
          FrostedTab(label: 'Année'),
        ],
        currentIndex: 0,
        onTap: (int _) {},
      ),
      () => find.text('Année'),
    ),
    _Case(
      'FrostedSegmentedControl',
      () => FrostedSegmentedControl(
        segments: const <String>['Jour', 'Semaine'],
        currentIndex: 0,
        onTap: (int _) {},
      ),
      () => find.text('Semaine'),
    ),
    _Case(
      'FrostedNavPill',
      () => FrostedNavPill(
        destinations: navItems,
        selectedIndex: 0,
        onDestinationSelected: (int _) {},
      ),
      () => find.byIcon(Icons.pie_chart),
    ),
    _Case(
      'FrostedBreadcrumb',
      () => FrostedBreadcrumb(
        crumbs: const <String>['Comptes', 'Courant'],
        onTap: (int _) {},
      ),
      () => find.text('Comptes'),
    ),
    _Case(
      'FrostedNavigationRail',
      () => FrostedNavigationRail(
        items: navItems,
        currentIndex: 0,
        onTap: (int _) {},
      ),
      () => find.text('Budget'),
    ),
    _Case(
      'FrostedDrawer',
      () => FrostedDrawer(items: navItems, currentIndex: 0, onTap: (int _) {}),
      () => find.text('Budget'),
    ),
    _Case(
      'FrostedSidebar',
      () => FrostedSidebar(
        sections: <FrostedSidebarSection>[
          FrostedSidebarSection(
            items: <FrostedSidebarItem>[
              FrostedSidebarItem(
                id: 'courses',
                icon: Icons.shopping_cart,
                label: 'Courses',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
      () => find.text('Courses'),
    ),
    _Case(
      'FrostedStepper',
      () => FrostedStepper(
        steps: const <FrostedStep>[
          FrostedStep(title: 'Montant'),
          FrostedStep(title: 'Catégorie'),
        ],
        currentStep: 0,
        onStepTapped: (int _) {},
      ),
      () => find.text('2'),
    ),
    _Case(
      'FrostedSplitButton',
      () => FrostedSplitButton.filled(
        label: 'Exporter',
        onPressed: () {},
        menuItems: <FrostedSplitMenuItem>[
          FrostedSplitMenuItem(label: 'CSV', onTap: () {}),
        ],
      ),
      () => find.text('Exporter'),
    ),
  ];

  /// The library paints no ink of its own — it hands the press to the
  /// ambient [ThemeData.splashFactory]. The suite therefore pumps a theme
  /// whose factory draws a plain circle, so what a press produces can be
  /// counted; the app-facing default is asserted separately.
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    InteractiveInkFeatureFactory? splashFactory,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(
          seedColor: seed,
        ).copyWith(splashFactory: splashFactory ?? InkSplash.splashFactory),
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  /// Settles a press far enough for its ink to have travelled. Inside a
  /// scrollable the tap recognizer only reports the press once it outlives
  /// [kPressTimeout], and the splash needs a further frame to start ticking.
  Future<void> pressAndSettle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// How many circles the whole app paints right now. The splash is the only
  /// circle a press adds, so the delta isolates it from the ones a component
  /// draws at rest — a radio dot, a badge, an avatar.
  int circlesPainted(WidgetTester tester) {
    int count = 0;
    expect(
      tester.renderObject(find.byType(MaterialApp)),
      paints
        ..everything((Symbol method, List<dynamic> arguments) {
          if (method == #drawCircle) count++;
          return true;
        }),
    );
    return count;
  }

  group('press ink', () {
    for (final _Case c in cases) {
      testWidgets("${c.name} splashes the theme's ink from the point pressed", (
        WidgetTester tester,
      ) async {
        await pump(tester, c.build());
        final Finder target = c.target();
        expect(target, findsOneWidget);

        final int resting = circlesPainted(tester);

        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(target),
        );
        await pressAndSettle(tester);

        expect(
          circlesPainted(tester),
          greaterThan(resting),
          reason: '${c.name} paints no ink while pressed',
        );

        await gesture.up();
        await tester.pumpAndSettle();
      });

      testWidgets('${c.name} leaves no ink behind once released', (
        WidgetTester tester,
      ) async {
        await pump(tester, c.build());
        final int resting = circlesPainted(tester);

        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(c.target()),
        );
        await pressAndSettle(tester);
        await gesture.up();
        await tester.pumpAndSettle();

        expect(circlesPainted(tester), resting);
      });

      testWidgets('${c.name} carries no ink widget of its own', (
        WidgetTester tester,
      ) async {
        await pump(tester, c.build());

        expect(find.byType(InkWell), findsNothing);
        expect(find.byType(InkResponse), findsNothing);
      });
    }

    testWidgets('the ink takes the splash colour of the theme', (
      WidgetTester tester,
    ) async {
      const Color splash = Color(0xFF00FF00);
      await tester.pumpWidget(
        MaterialApp(
          theme: FrostedTheme.dark(seedColor: seed).copyWith(
            splashFactory: InkSplash.splashFactory,
            splashColor: splash,
          ),
          home: Scaffold(
            body: Center(
              child: FrostedButton.filled(
                label: 'Supprimer',
                destructive: true,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(FrostedButton)),
      );
      await pressAndSettle(tester);

      Color? painted;
      expect(
        tester.renderObject(find.byType(FrostedButton)),
        paints
          ..something((Symbol method, List<dynamic> arguments) {
            if (method != #drawCircle) return false;
            painted = (arguments[2] as Paint).color;
            return true;
          }),
      );
      expect(painted, isNotNull);
      expect(
        <double>[painted!.r, painted!.g, painted!.b],
        <double>[splash.r, splash.g, splash.b],
        reason: 'the ink tints itself instead of taking the theme splash',
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a surface paints no ink the factory did not draw', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        FrostedButton.filled(label: 'Valider', onPressed: () {}),
        splashFactory: InkSparkle.constantTurbulenceSeedSplashFactory,
      );
      final int resting = circlesPainted(tester);

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(FrostedButton)),
      );
      await pressAndSettle(tester);

      expect(
        circlesPainted(tester),
        resting,
        reason: 'the sparkle draws no circle — this one is the library\'s own',
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
