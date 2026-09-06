import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

class _Case {
  const _Case(this.name, this.build, this.target, {Finder Function()? root})
    : _root = root;

  final String name;
  final Widget Function() build;

  final Finder Function() target;

  final Finder Function()? _root;

  Finder Function() get root => _root ?? target;
}

class _InkFrame {
  const _InkFrame(this.surface, this.clips);

  final RRect surface;

  final List<bool Function(Offset)> clips;

  bool covers(Offset point) =>
      clips.every((bool Function(Offset) clip) => clip(point));
}

void main() {
  const Color seed = Color(0xFF7C5CFF);
  const Color splash = Color(0xFF00FF00);

  const double boundaryMargin = 0.25;

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
      'FrostedFab.extended',
      () => FrostedFab.extended(
        icon: Icons.add,
        label: 'Ajouter',
        onPressed: () {},
      ),
      () => find.byType(FrostedFab),
    ),
    _Case(
      'FrostedCard',
      () => FrostedCard(onTap: () {}, child: const Text('Solde')),
      () => find.byType(FrostedCard),
    ),
    _Case(
      'FrostedChip',
      () => FrostedChip.assist(label: 'Filtrer', onTap: () {}),
      () => find.byType(FrostedChip),
    ),
    _Case(
      'FrostedListTile',
      () => FrostedListTile(title: 'Courses', onTap: () {}),
      () => find.byType(FrostedListTile),
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
      root: () => find.byType(FrostedToggleButtons),
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
      root: () => find.byType(FrostedSplitButton),
    ),
    _Case(
      'FrostedExpansionTile',
      () =>
          const FrostedExpansionTile(title: 'Détails', child: Text('Contenu')),
      () => find.text('Détails'),
      root: () => find.byType(FrostedExpansionTile),
    ),
    _Case(
      'FrostedSegmentedControl',
      () => FrostedSegmentedControl(
        segments: const <String>['6 mois', '12 mois'],
        currentIndex: 0,
        onTap: (int _) {},
        segmentWidth: 88,
      ),
      () => find.text('12 mois'),
      root: () => find.byType(FrostedSegmentedControl),
    ),
    _Case(
      'FrostedNavPill',
      () => FrostedNavPill(
        destinations: navItems,
        selectedIndex: 0,
        onDestinationSelected: (int _) {},
      ),
      () => find.byIcon(Icons.pie_chart),
      root: () => find.byType(FrostedNavPill),
    ),
    _Case(
      'FrostedNavigationRail',
      () => FrostedNavigationRail(
        items: navItems,
        currentIndex: 0,
        onTap: (int _) {},
      ),
      () => find.text('Budget'),
      root: () => find.byType(FrostedNavigationRail),
    ),
    _Case(
      'FrostedDrawer',
      () => FrostedDrawer(items: navItems, currentIndex: 0, onTap: (int _) {}),
      () => find.text('Budget'),
      root: () => find.byType(FrostedDrawer),
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
      root: () => find.byType(FrostedSidebar),
    ),
  ];

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(
          seedColor: seed,
        ).copyWith(splashFactory: InkSplash.splashFactory, splashColor: splash),
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  _InkFrame? inkFrame(WidgetTester tester, Finder root) {
    _InkFrame? frame;
    Offset origin = Offset.zero;
    RRect? lastRRect;
    final List<bool Function(Offset)> clips = <bool Function(Offset)>[];
    final List<Offset> savedOrigins = <Offset>[];
    final List<int> savedClipCounts = <int>[];

    expect(
      tester.renderObject(root),
      paints..everything((Symbol method, List<dynamic> arguments) {
        switch (method) {
          case #save:
          case #saveLayer:
            savedOrigins.add(origin);
            savedClipCounts.add(clips.length);
          case #restore:
            if (savedOrigins.isNotEmpty) {
              origin = savedOrigins.removeLast();
              clips.length = savedClipCounts.removeLast();
            }
          case #translate:
            origin += Offset(arguments[0] as double, arguments[1] as double);
          case #clipRect:
            final Rect rect = (arguments[0] as Rect).shift(origin);
            clips.add(rect.contains);
          case #clipRRect:
            final RRect rrect = (arguments[0] as RRect).shift(origin);
            clips.add(rrect.contains);
          case #clipPath:
            final Path path = (arguments[0] as Path).shift(origin);
            clips.add(path.contains);
          case #drawRRect:
            lastRRect = (arguments[0] as RRect).shift(origin);
          case #drawCircle:
            final Color color = (arguments[2] as Paint).color;
            final bool isInk =
                color.r == splash.r &&
                color.g == splash.g &&
                color.b == splash.b;
            if (isInk && frame == null && lastRRect != null) {
              frame = _InkFrame(
                lastRRect!,
                List<bool Function(Offset)>.of(clips),
              );
            }
        }
        return true;
      }),
    );
    return frame;
  }

  void expectInkTakesSurfaceShape(_InkFrame? frame, String name) {
    expect(frame, isNotNull, reason: '$name paints no ink over a surface');
    final RRect surface = frame!.surface;
    final RRect inside = surface.deflate(boundaryMargin);
    final RRect outside = surface.inflate(boundaryMargin);

    const int steps = 32;
    for (int i = 0; i <= steps; i++) {
      for (int j = 0; j <= steps; j++) {
        final Offset point = Offset(
          surface.left + surface.width * i / steps,
          surface.top + surface.height * j / steps,
        );
        final bool within = inside.contains(point);
        if (!within && outside.contains(point)) continue;
        expect(
          frame.covers(point),
          within,
          reason: within
              ? '$name leaves $point of its surface bare of ink'
              : '$name spills ink onto $point, outside its surface',
        );
      }
    }
  }

  group('press ink shape', () {
    for (final _Case c in cases) {
      testWidgets('${c.name} keeps its ink to the shape it is morphing into', (
        WidgetTester tester,
      ) async {
        await pump(tester, c.build());
        final Finder root = c.target();
        expect(root, findsOneWidget);

        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(root),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 110));
        await tester.pump(const Duration(milliseconds: 60));

        expectInkTakesSurfaceShape(inkFrame(tester, c.root()), c.name);

        await gesture.up();
        await tester.pumpAndSettle();
      });

      testWidgets('${c.name} keeps its ink to the shape once the morph lands', (
        WidgetTester tester,
      ) async {
        await pump(tester, c.build());

        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(c.target()),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 110));
        await tester.pump(const Duration(milliseconds: 250));

        expectInkTakesSurfaceShape(inkFrame(tester, c.root()), c.name);

        await gesture.up();
        await tester.pumpAndSettle();
      });
    }
  });
}
