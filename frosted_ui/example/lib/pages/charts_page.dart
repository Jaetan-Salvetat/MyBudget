import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../widgets/section.dart';

class ChartsPage extends StatelessWidget {
  const ChartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        FrostedSpacing.sp4,
        FrostedTopBar.bodyTopPadding(context) + FrostedSpacing.sp2,
        FrostedSpacing.sp4,
        FrostedSpacing.sp7,
      ),
      children: const <Widget>[
        Section(title: 'Column chart', child: _ColumnChartDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Stacked bar', child: _StackedBarDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Diverging bar', child: _DivergingBarDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Legend and dots', child: _LegendDemo()),
      ],
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: FrostedSpacing.sp2),
      child: Text(
        label,
        style: FrostedTypeScale.labelSmall.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _ColumnChartDemo extends StatefulWidget {
  const _ColumnChartDemo();

  @override
  State<_ColumnChartDemo> createState() => _ColumnChartDemoState();
}

class _ColumnChartDemoState extends State<_ColumnChartDemo> {
  static const List<String> _months = <String>[
    'JAN',
    'FEV',
    'MAR',
    'AVR',
    'MAI',
    'JUN',
    'JUL',
    'AOU',
  ];
  static const List<double> _incomes = <double>[
    2400,
    2400,
    2600,
    2400,
    3100,
    2400,
    2400,
    2500,
  ];
  static const List<double> _expenses = <double>[
    1800,
    2200,
    1500,
    2600,
    1900,
    2100,
    2800,
    1700,
  ];

  int? _selected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _Caption('Expenses filling the month they belong to'),
        FrostedColumnChart(
          columns: <FrostedColumnData>[
            for (int index = 0; index < _months.length; index++)
              FrostedColumnData(
                value: _incomes[index] > _expenses[index]
                    ? _incomes[index]
                    : _expenses[index],
                fill: _expenses[index],
                label: _months[index],
              ),
          ],
          onColumnTap: (int index) => setState(() => _selected = index),
        ),
        const SizedBox(height: FrostedSpacing.sp3),
        FrostedChartLegend(
          entries: <FrostedLegendEntry>[
            FrostedLegendEntry(color: cs.primaryContainer, label: 'in'),
            FrostedLegendEntry(color: cs.primary, label: 'out'),
          ],
          trailing: Text(
            _selected == null ? 'tap a column' : _months[_selected!],
          ),
        ),
      ],
    );
  }
}

class _StackedBarDemo extends StatefulWidget {
  const _StackedBarDemo();

  @override
  State<_StackedBarDemo> createState() => _StackedBarDemoState();
}

class _StackedBarDemoState extends State<_StackedBarDemo> {
  bool _shuffled = false;

  List<FrostedBarSegment> _segments(ColorScheme cs) {
    final List<Color> colors = <Color>[
      cs.primary,
      cs.tertiary,
      cs.secondary,
      cs.error,
    ];
    final List<double> values = _shuffled
        ? <double>[12, 34, 21, 8]
        : <double>[42, 18, 9, 4];

    return <FrostedBarSegment>[
      for (int index = 0; index < values.length; index++)
        FrostedBarSegment(value: values[index], color: colors[index]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _Caption('Breakdown'),
        FrostedStackedBar(segments: _segments(cs)),
        const SizedBox(height: FrostedSpacing.sp4),
        const _Caption('Breakdown · radius 2'),
        FrostedStackedBar(segments: _segments(cs), radius: 2),
        const SizedBox(height: FrostedSpacing.sp4),
        const _Caption('Two shares, thickness 9'),
        FrostedStackedBar(
          segments: <FrostedBarSegment>[
            FrostedBarSegment(value: 62, color: cs.primary),
            FrostedBarSegment(value: 38, color: cs.primaryContainer),
          ],
          thickness: 9,
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        const _Caption('Animated · thickness 4, gap 3'),
        FrostedStackedBar(
          segments: _segments(cs),
          thickness: 4,
          gap: 3,
          animated: true,
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        FrostedButton.tonal(
          label: 'Shuffle weights',
          onPressed: () => setState(() => _shuffled = !_shuffled),
        ),
      ],
    );
  }
}

class _DivergingBarDemo extends StatelessWidget {
  const _DivergingBarDemo();

  static const List<double> _deltas = <double>[128, -74, 46, -22];

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double widest = _deltas
        .map((double delta) => delta.abs())
        .reduce((double a, double b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _Caption('Signed deltas'),
        for (final double delta in _deltas)
          Padding(
            padding: const EdgeInsets.only(bottom: FrostedSpacing.sp1),
            child: FrostedDivergingBar(
              factor: delta.abs() / widest,
              side: delta >= 0
                  ? FrostedDivergingSide.trailing
                  : FrostedDivergingSide.leading,
              color: delta >= 0 ? cs.error : cs.tertiary,
            ),
          ),
      ],
    );
  }
}

class _LegendDemo extends StatelessWidget {
  const _LegendDemo();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _Caption('Dots'),
        Row(
          children: <Widget>[
            FrostedChartDot(color: cs.primary),
            const SizedBox(width: FrostedSpacing.sp2),
            FrostedChartDot(color: cs.tertiary, size: 9, radius: 3),
            const SizedBox(width: FrostedSpacing.sp2),
            FrostedChartDot(color: cs.error, size: 12),
          ],
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        const _Caption('Legend without a divider'),
        FrostedChartLegend(
          showDivider: false,
          entries: <FrostedLegendEntry>[
            FrostedLegendEntry(color: cs.primary, label: 'housing'),
            FrostedLegendEntry(color: cs.tertiary, label: 'food'),
            FrostedLegendEntry(color: cs.secondary, label: 'transport'),
          ],
        ),
      ],
    );
  }
}
