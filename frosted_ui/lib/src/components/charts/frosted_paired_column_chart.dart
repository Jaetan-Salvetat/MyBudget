import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_chart_tokens.dart';
import '../../foundations/frosted_type_scale.dart';

@immutable
class FrostedPairedColumnData {
  const FrostedPairedColumnData({
    required this.primary,
    required this.secondary,
    this.label = '',
  });

  final double primary;
  final double secondary;
  final String label;
}

class FrostedPairedColumnChart extends StatelessWidget {
  const FrostedPairedColumnChart({
    required this.columns,
    this.height = FrostedChartTokens.columnChartHeight,
    this.primaryColor,
    this.secondaryColor,
    this.labelStyle,
    this.maxAxisLabels = FrostedChartTokens.axisLabelBudget,
    this.onColumnTap,
    super.key,
  });

  final List<FrostedPairedColumnData> columns;
  final double height;
  final Color? primaryColor;
  final Color? secondaryColor;
  final TextStyle? labelStyle;
  final int maxAxisLabels;
  final ValueChanged<int>? onColumnTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double scale = _scale();
    final bool hasLabels = columns.any(
      (FrostedPairedColumnData column) => column.label.isNotEmpty,
    );

    return Column(
      children: <Widget>[
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int index = 0; index < columns.length; index++)
                Expanded(
                  child: _Pair(
                    data: columns[index],
                    scale: scale,
                    primaryColor: primaryColor ?? cs.primaryContainer,
                    secondaryColor: secondaryColor ?? cs.primary,
                    onTap: onColumnTap == null
                        ? null
                        : () => onColumnTap!(index),
                  ),
                ),
            ],
          ),
        ),
        if (hasLabels) ...<Widget>[
          const SizedBox(height: FrostedChartTokens.axisGap),
          Row(
            children: <Widget>[
              for (int index = 0; index < columns.length; index++)
                Expanded(
                  child: Text(
                    _tick(index),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style:
                        labelStyle ??
                        FrostedTypeScale.labelSmall.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  double _scale() {
    double scale = 0;
    for (final FrostedPairedColumnData column in columns) {
      scale = math.max(scale, math.max(column.primary, column.secondary));
    }
    return scale;
  }

  String _tick(int index) {
    final bool kept = (columns.length - 1 - index).isEven;
    if (columns.length > maxAxisLabels && !kept) return '';
    return columns[index].label;
  }
}

class _Pair extends StatelessWidget {
  const _Pair({
    required this.data,
    required this.scale,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onTap,
  });

  final FrostedPairedColumnData data;
  final double scale;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget pair = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FrostedChartTokens.columnGap / 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: _Bar(factor: _factorOf(data.primary), color: primaryColor),
          ),
          const SizedBox(width: FrostedChartTokens.barGap),
          Expanded(
            child: _Bar(
              factor: _factorOf(data.secondary),
              color: secondaryColor,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return pair;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: pair,
    );
  }

  double _factorOf(double value) => scale <= 0 ? 0 : value / scale;
}

class _Bar extends StatelessWidget {
  const _Bar({required this.factor, required this.color});

  final double factor;
  final Color color;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    child: FractionallySizedBox(
      widthFactor: 1,
      heightFactor: factor.clamp(FrostedChartTokens.columnMinFactor, 1.0),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) =>
            ClipRRect(
              borderRadius: BorderRadius.circular(
                math.min(
                  FrostedChartTokens.columnRadius,
                  constraints.biggest.shortestSide / 2,
                ),
              ),
              child: ColoredBox(color: color),
            ),
      ),
    ),
  );
}
