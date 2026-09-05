import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/src/components/charts/_stacked_bar_fractions.dart';
import 'package:material_ui/material_ui.dart';

const Color _red = Color(0xFFFF0000);
const Color _blue = Color(0xFF0000FF);

Widget _host(Widget child, {double width = 200}) => MaterialApp(
  theme: FrostedTheme.dark(seedColor: const Color(0xFF7C5CFF)),
  home: Scaffold(
    body: Center(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

Finder _paintedBoxes() => find.descendant(
  of: find.byType(FrostedColumnChart),
  matching: find.byType(ColoredBox),
);

List<BorderRadius> _radiiOf(WidgetTester tester, Finder owner) => tester
    .widgetList<Container>(
      find.descendant(of: owner, matching: find.byType(Container)),
    )
    .map((Container container) => container.decoration)
    .whereType<BoxDecoration>()
    .map((BoxDecoration decoration) => decoration.borderRadius)
    .whereType<BorderRadius>()
    .toList();

List<double> _fractions(StackedBarFractions bars) => <double>[
  for (int i = 0; i < bars.length; i++) bars[i].fraction,
];

void main() {
  group('StackedBarFractions.of', () {
    test('normalises the segment weights', () {
      final StackedBarFractions bars =
          StackedBarFractions.of(const <FrostedBarSegment>[
            FrostedBarSegment(value: 30, color: _red),
            FrostedBarSegment(value: 10, color: _blue),
          ]);

      expect(_fractions(bars), <double>[0.75, 0.25]);
    });

    test('drops segments without weight', () {
      final StackedBarFractions bars =
          StackedBarFractions.of(const <FrostedBarSegment>[
            FrostedBarSegment(value: 4, color: _red),
            FrostedBarSegment(value: 0, color: _blue),
            FrostedBarSegment(value: -2, color: _blue),
          ]);

      expect(bars.length, 1);
      expect(bars[0].fraction, 1);
    });

    test('is empty when nothing has weight', () {
      expect(
        StackedBarFractions.of(const <FrostedBarSegment>[
          FrostedBarSegment(value: 0, color: _red),
        ]).isEmpty,
        isTrue,
      );
    });
  });

  group('StackedBarFractions.lerp', () {
    test('interpolates fractions of matching bars', () {
      final StackedBarFractions bars = StackedBarFractions.lerp(
        StackedBarFractions.of(const <FrostedBarSegment>[
          FrostedBarSegment(value: 1, color: _red),
          FrostedBarSegment(value: 3, color: _blue),
        ]),
        StackedBarFractions.of(const <FrostedBarSegment>[
          FrostedBarSegment(value: 3, color: _red),
          FrostedBarSegment(value: 1, color: _blue),
        ]),
        0.5,
      );

      expect(_fractions(bars), <double>[0.5, 0.5]);
    });

    test('grows a missing bar from zero', () {
      final StackedBarFractions bars = StackedBarFractions.lerp(
        StackedBarFractions.of(const <FrostedBarSegment>[
          FrostedBarSegment(value: 1, color: _red),
        ]),
        StackedBarFractions.of(const <FrostedBarSegment>[
          FrostedBarSegment(value: 1, color: _red),
          FrostedBarSegment(value: 1, color: _blue),
        ]),
        0.5,
      );

      expect(_fractions(bars), <double>[0.75, 0.25]);
    });
  });

  group('FrostedStackedBar', () {
    testWidgets('splits the free width across the segments', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const FrostedStackedBar(
            segments: <FrostedBarSegment>[
              FrostedBarSegment(value: 1, color: _red),
              FrostedBarSegment(value: 3, color: _blue),
            ],
            gap: 2,
          ),
          width: 100,
        ),
      );

      final Iterable<Size> sizes = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(FrostedStackedBar),
              matching: find.byType(Container),
            ),
          )
          .map(
            (Container container) => tester.getSize(find.byWidget(container)),
          );

      expect(sizes.map((Size size) => size.width), <double>[24.5, 73.5]);
      expect(
        sizes.map((Size size) => size.height),
        everyElement(FrostedChartTokens.barThickness),
      );
    });

    testWidgets('rounds a segment no further than it can carry', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const FrostedStackedBar(
            segments: <FrostedBarSegment>[
              FrostedBarSegment(value: 1, color: _red),
              FrostedBarSegment(value: 99, color: _blue),
            ],
            gap: 2,
          ),
          width: 100,
        ),
      );

      expect(_radiiOf(tester, find.byType(FrostedStackedBar)), <BorderRadius>[
        BorderRadius.circular(0.49),
        BorderRadius.circular(FrostedChartTokens.barThickness / 2),
      ]);
    });

    testWidgets('keeps its thickness when there is nothing to show', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const FrostedStackedBar(
            segments: <FrostedBarSegment>[],
            thickness: 4,
          ),
        ),
      );

      expect(tester.getSize(find.byType(FrostedStackedBar)).height, 4);
    });

    testWidgets('animates towards the new segments', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const FrostedStackedBar(
            segments: <FrostedBarSegment>[
              FrostedBarSegment(value: 1, color: _red),
            ],
            animated: true,
            gap: 0,
          ),
          width: 100,
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        _host(
          const FrostedStackedBar(
            segments: <FrostedBarSegment>[
              FrostedBarSegment(value: 1, color: _red),
              FrostedBarSegment(value: 1, color: _blue),
            ],
            animated: true,
            gap: 0,
          ),
          width: 100,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final double lastWidth = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(FrostedStackedBar),
              matching: find.byType(Container),
            ),
          )
          .map(
            (Container container) =>
                tester.getSize(find.byWidget(container)).width,
          )
          .last;

      expect(lastWidth, greaterThan(0));
      expect(lastWidth, lessThan(50));
    });
  });

  group('FrostedColumnChart', () {
    const List<FrostedColumnData> columns = <FrostedColumnData>[
      FrostedColumnData(value: 100, fill: 50, label: 'JAN'),
      FrostedColumnData(value: 50, fill: 50, label: 'FEV'),
      FrostedColumnData(value: 0, label: 'MAR'),
    ];

    List<double> heightFactors(WidgetTester tester) => tester
        .widgetList<FractionallySizedBox>(
          find.descendant(
            of: find.byType(FrostedColumnChart),
            matching: find.byType(FractionallySizedBox),
          ),
        )
        .map((FractionallySizedBox box) => box.heightFactor ?? 0)
        .toList();

    testWidgets('scales the columns on the tallest value', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const FrostedColumnChart(columns: columns)),
      );

      expect(heightFactors(tester), <double>[
        1,
        0.5,
        0.5,
        1,
        FrostedChartTokens.columnMinFactor,
      ]);
    });

    testWidgets('paints a track and its fill, nothing else', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const FrostedColumnChart(
            columns: <FrostedColumnData>[
              FrostedColumnData(value: 100, fill: 60),
            ],
            height: 100,
          ),
        ),
      );

      expect(_paintedBoxes(), findsNWidgets(2));
    });

    testWidgets('thins out the axis labels when there are too many', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FrostedColumnChart(
            columns: <FrostedColumnData>[
              for (int index = 0; index < 8; index++)
                FrostedColumnData(value: 10, label: 'M$index'),
            ],
            maxAxisLabels: 6,
          ),
        ),
      );

      expect(find.text('M7'), findsOneWidget);
      expect(find.text('M5'), findsOneWidget);
      expect(find.text('M6'), findsNothing);
    });

    testWidgets('reports the tapped column', (WidgetTester tester) async {
      int? tapped;
      await tester.pumpWidget(
        _host(
          FrostedColumnChart(
            columns: columns,
            onColumnTap: (int index) => tapped = index,
          ),
        ),
      );

      await tester.tap(
        find
            .descendant(
              of: find.byType(FrostedColumnChart),
              matching: find.byType(GestureDetector),
            )
            .at(1),
      );

      expect(tapped, 1);
    });
  });

  group('FrostedDivergingBar', () {
    testWidgets('draws a trailing bar right of the axis', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const FrostedDivergingBar(
            factor: 0.5,
            side: FrostedDivergingSide.trailing,
            color: _red,
          ),
          width: 100,
        ),
      );

      final double axis = tester.getCenter(find.byType(FrostedDivergingBar)).dx;

      expect(
        tester.getTopLeft(find.byType(FractionallySizedBox)).dx,
        closeTo(axis, 1),
      );
    });

    testWidgets('draws a leading bar left of the axis', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const FrostedDivergingBar(
            factor: 0.5,
            side: FrostedDivergingSide.leading,
            color: _red,
          ),
          width: 100,
        ),
      );

      final double axis = tester.getCenter(find.byType(FrostedDivergingBar)).dx;

      expect(
        tester.getBottomRight(find.byType(FractionallySizedBox)).dx,
        closeTo(axis, 1),
      );
    });
  });

  group('FrostedDivergingBar shape', () {
    testWidgets('rounds the far end and squares the one on the axis', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: <Widget>[
              FrostedDivergingBar(
                factor: 0.5,
                side: FrostedDivergingSide.trailing,
                color: _red,
              ),
              FrostedDivergingBar(
                factor: 0.5,
                side: FrostedDivergingSide.leading,
                color: _blue,
              ),
            ],
          ),
          width: 100,
        ),
      );

      const Radius full = Radius.circular(FrostedRadius.full);

      expect(
        _radiiOf(tester, find.byType(FrostedDivergingBar).first),
        <BorderRadius>[const BorderRadius.horizontal(right: full)],
      );
      expect(
        _radiiOf(tester, find.byType(FrostedDivergingBar).last),
        <BorderRadius>[const BorderRadius.horizontal(left: full)],
      );
    });
  });

  group('FrostedChartLegend', () {
    testWidgets('lists its entries and its trailing note', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const FrostedChartLegend(
            entries: <FrostedLegendEntry>[
              FrostedLegendEntry(color: _red, label: 'entré'),
              FrostedLegendEntry(color: _blue, label: 'sorti'),
            ],
            trailing: Text('tap → le mois'),
          ),
          width: 320,
        ),
      );

      expect(find.text('entré'), findsOneWidget);
      expect(find.text('sorti'), findsOneWidget);
      expect(find.text('tap → le mois'), findsOneWidget);
      expect(find.byType(FrostedChartDot), findsNWidgets(2));
    });
  });

  group('FrostedChartDot', () {
    testWidgets('is round by default and squared when given a radius', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FrostedChartDot(color: _red),
              FrostedChartDot(color: _blue, radius: 3),
            ],
          ),
        ),
      );

      final List<BoxDecoration> decorations = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((DecoratedBox box) => box.decoration)
          .whereType<BoxDecoration>()
          .where(
            (BoxDecoration decoration) =>
                decoration.color == _red || decoration.color == _blue,
          )
          .toList();

      expect(decorations.first.shape, BoxShape.circle);
      expect(decorations.last.borderRadius, BorderRadius.circular(3));
    });
  });
}
