import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

void main() {
  const Color seed = Color(0xFF2A55D3);

  const List<FrostedNavItem> destinations = <FrostedNavItem>[
    FrostedNavItem(icon: Icons.dashboard_outlined, label: 'Accueil'),
    FrostedNavItem(icon: Icons.swap_vert_outlined, label: 'Transactions'),
    FrostedNavItem(icon: Icons.account_balance_outlined, label: 'Comptes'),
  ];

  Future<void> pump(
    WidgetTester tester, {
    int selectedIndex = 0,
    ValueChanged<int>? onDestinationSelected,
    List<FrostedNavItem> items = destinations,
    FrostedNavAction? action,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.light(seedColor: seed),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: FrostedNavPill(
              destinations: items,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected ?? (int _) {},
              action: action,
            ),
          ),
        ),
      ),
    );
  }

  double contrastRatio(Color a, Color b) {
    final double first = a.computeLuminance();
    final double second = b.computeLuminance();
    final double lighter = math.max(first, second);
    final double darker = math.min(first, second);
    return (lighter + 0.05) / (darker + 0.05);
  }

  Future<void> pumpThemed(
    WidgetTester tester, {
    required ThemeData theme,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: FrostedNavPill(
              destinations: destinations,
              selectedIndex: 0,
              onDestinationSelected: (int _) {},
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration selectedDecoration(WidgetTester tester) {
    final AnimatedContainer container = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text('Accueil'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    return container.decoration! as BoxDecoration;
  }

  Color selectedLabelColor(WidgetTester tester) {
    return tester.widget<Text>(find.text('Accueil')).style!.color!;
  }

  group('FrostedNavPill selection legibility', () {
    testWidgets('the selected pill stands out from the surface in light', (
      WidgetTester tester,
    ) async {
      final ThemeData theme = FrostedTheme.light(seedColor: seed);
      await pumpThemed(tester, theme: theme);
      await tester.pumpAndSettle();

      final Color surface = theme.colorScheme.surface;
      final Color pill = Color.alphaBlend(
        selectedDecoration(tester).color!,
        surface,
      );

      expect(contrastRatio(pill, surface), greaterThanOrEqualTo(1.25));
    });

    testWidgets('the selected pill stands out from the surface in dark', (
      WidgetTester tester,
    ) async {
      final ThemeData theme = FrostedTheme.dark(seedColor: seed);
      await pumpThemed(tester, theme: theme);
      await tester.pumpAndSettle();

      final Color surface = theme.colorScheme.surface;
      final Color pill = Color.alphaBlend(
        selectedDecoration(tester).color!,
        surface,
      );

      expect(contrastRatio(pill, surface), greaterThanOrEqualTo(1.25));
    });

    testWidgets('the selected label stays readable on its own pill', (
      WidgetTester tester,
    ) async {
      for (final ThemeData theme in <ThemeData>[
        FrostedTheme.light(seedColor: seed),
        FrostedTheme.dark(seedColor: seed),
      ]) {
        await pumpThemed(tester, theme: theme);
        await tester.pumpAndSettle();

        final Color pill = Color.alphaBlend(
          selectedDecoration(tester).color!,
          theme.colorScheme.surface,
        );

        expect(
          contrastRatio(selectedLabelColor(tester), pill),
          greaterThanOrEqualTo(4.5),
        );
      }
    });
  });

  group('FrostedNavPill destination centring', () {
    testWidgets('an unlabelled icon sits at the centre of its tap target', (
      WidgetTester tester,
    ) async {
      await pump(tester, selectedIndex: 0);
      await tester.pumpAndSettle();

      final Finder icon = find.byIcon(Icons.account_balance_outlined);
      final Finder target = find
          .ancestor(of: icon, matching: find.byType(AnimatedContainer))
          .first;

      expect(
        tester.getCenter(icon).dx,
        moreOrLessEquals(tester.getCenter(target).dx, epsilon: 0.01),
      );
    });

    testWidgets('the selected icon and label stay centred together', (
      WidgetTester tester,
    ) async {
      await pump(tester, selectedIndex: 0);
      await tester.pumpAndSettle();

      final Finder target = find
          .ancestor(
            of: find.text('Accueil'),
            matching: find.byType(AnimatedContainer),
          )
          .first;
      final Rect icon = tester.getRect(find.byIcon(Icons.dashboard_outlined));
      final Rect label = tester.getRect(find.text('Accueil'));

      expect(
        (icon.left + label.right) / 2,
        moreOrLessEquals(tester.getCenter(target).dx, epsilon: 0.01),
      );
    });
  });

  group('FrostedNavPill labels', () {
    testWidgets('only the selected destination carries a visible label', (
      WidgetTester tester,
    ) async {
      await pump(tester, selectedIndex: 0);
      await tester.pumpAndSettle();

      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Transactions'), findsNothing);
      expect(find.text('Comptes'), findsNothing);
    });

    testWidgets('every destination keeps its icon', (
      WidgetTester tester,
    ) async {
      await pump(tester, selectedIndex: 0);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.dashboard_outlined), findsOneWidget);
      expect(find.byIcon(Icons.swap_vert_outlined), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_outlined), findsOneWidget);
    });

    testWidgets('changing the selection moves the label', (
      WidgetTester tester,
    ) async {
      await pump(tester, selectedIndex: 0);
      await tester.pumpAndSettle();

      await pump(tester, selectedIndex: 2);
      await tester.pumpAndSettle();

      expect(find.text('Accueil'), findsNothing);
      expect(find.text('Comptes'), findsOneWidget);
    });

    testWidgets('the selected destination prefers its selectedIcon', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        selectedIndex: 0,
        items: const <FrostedNavItem>[
          FrostedNavItem(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            label: 'Accueil',
          ),
          FrostedNavItem(icon: Icons.swap_vert_outlined, label: 'Transactions'),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.dashboard), findsOneWidget);
      expect(find.byIcon(Icons.dashboard_outlined), findsNothing);
    });
  });

  group('FrostedNavPill interaction', () {
    testWidgets('tapping an unlabelled destination reports its index', (
      WidgetTester tester,
    ) async {
      int? selected;
      await pump(
        tester,
        selectedIndex: 0,
        onDestinationSelected: (int i) => selected = i,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.account_balance_outlined));
      await tester.pumpAndSettle();

      expect(selected, 2);
    });

    testWidgets('tapping the selected destination still reports its index', (
      WidgetTester tester,
    ) async {
      int? selected;
      await pump(
        tester,
        selectedIndex: 1,
        onDestinationSelected: (int i) => selected = i,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Transactions'));
      await tester.pumpAndSettle();

      expect(selected, 1);
    });
  });

  group('FrostedNavPill accessibility', () {
    testWidgets('every destination meets the Android tap target guideline', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, selectedIndex: 0);
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('an unlabelled destination keeps its semantics label', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, selectedIndex: 0);
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Comptes'), findsOneWidget);
      handle.dispose();
    });
  });

  group('FrostedNavPill badges', () {
    testWidgets('a badge renders on an unlabelled destination', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        selectedIndex: 0,
        items: const <FrostedNavItem>[
          FrostedNavItem(icon: Icons.dashboard_outlined, label: 'Accueil'),
          FrostedNavItem(
            icon: Icons.swap_vert_outlined,
            label: 'Transactions',
            badge: FrostedBadge.count(3),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Transactions'), findsNothing);
      expect(find.byType(FrostedBadgeView), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });

  group('FrostedNavPill action', () {
    testWidgets('renders no action slot when none is given', (
      WidgetTester tester,
    ) async {
      await pump(tester, selectedIndex: 0);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });

    testWidgets('renders the action alongside the destinations', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        selectedIndex: 0,
        action: FrostedNavAction(
          icon: Icons.auto_awesome,
          label: 'Ajout rapide',
          onPressed: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.byIcon(Icons.dashboard_outlined), findsOneWidget);
    });

    testWidgets('tapping the action fires it without selecting a destination', (
      WidgetTester tester,
    ) async {
      int? selected;
      int pressed = 0;
      await pump(
        tester,
        selectedIndex: 0,
        onDestinationSelected: (int i) => selected = i,
        action: FrostedNavAction(
          icon: Icons.auto_awesome,
          label: 'Ajout rapide',
          onPressed: () => pressed++,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pumpAndSettle();

      expect(pressed, 1);
      expect(selected, isNull);
    });

    testWidgets('the action carries its own semantics label', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        selectedIndex: 0,
        action: FrostedNavAction(
          icon: Icons.auto_awesome,
          label: 'Ajout rapide',
          onPressed: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Ajout rapide'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the action meets the Android tap target guideline', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        selectedIndex: 0,
        action: FrostedNavAction(
          icon: Icons.auto_awesome,
          label: 'Ajout rapide',
          onPressed: () {},
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('the action fills itself with the accent as the one command', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        selectedIndex: 0,
        action: FrostedNavAction(
          icon: Icons.auto_awesome,
          label: 'Ajout rapide',
          onPressed: () {},
        ),
      );
      await tester.pumpAndSettle();

      final ColorScheme cs = FrostedTheme.light(seedColor: seed).colorScheme;
      final DecoratedBox box = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.byIcon(Icons.auto_awesome),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final BoxDecoration decoration = box.decoration as BoxDecoration;

      expect(decoration.color, cs.primary);
      expect(decoration.shape, BoxShape.circle);
    });
  });

  group('FrostedNavPill material', () {
    testWidgets('stays on a glass level its own height can actually blur', (
      WidgetTester tester,
    ) async {
      await pump(tester, selectedIndex: 0);
      await tester.pumpAndSettle();

      final FrostedGlass glass = tester.widget<FrostedGlass>(
        find.descendant(
          of: find.byType(FrostedNavPill),
          matching: find.byType(FrostedGlass),
        ),
      );
      final double height = tester.getSize(find.byType(FrostedNavPill)).height;
      final FrostedGlassLevelSpec spec = FrostedGlassTokens.standard().specFor(
        glass.level,
      );

      expect(spec.blurSigma, lessThan(height));
      expect(spec.lightVeilOpacity, lessThanOrEqualTo(0.25));
    });
  });

  group('FrostedNavPill layout', () {
    testWidgets('the glass keeps hugging under a tight full-width parent', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FrostedTheme.light(seedColor: seed),
          home: Scaffold(
            body: const SizedBox.shrink(),
            bottomNavigationBar: FrostedNavPill(
              destinations: destinations,
              selectedIndex: 0,
              onDestinationSelected: (int _) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final double screen = tester.getSize(find.byType(Scaffold)).width;
      final double glass = tester.getSize(find.byType(FrostedGlass)).width;

      expect(glass, lessThan(screen));
    });

    testWidgets('the pill hugs its destinations instead of filling the width', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pump(tester, selectedIndex: 0);
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(FrostedNavPill)).width, lessThan(400));
    });
  });
}
