import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_chart_tokens.dart';
import '../../foundations/frosted_type_scale.dart';

@immutable
class FrostedColumnData {
  const FrostedColumnData({
    required this.value,
    this.fill = 0,
    this.label = '',
  });

  final double value;
  final double fill;
  final String label;
}

class FrostedColumnChart extends StatelessWidget {
  const FrostedColumnChart({
    required this.columns,
    this.height = FrostedChartTokens.columnChartHeight,
    this.trackColor,
    this.fillColor,
    this.labelStyle,
    this.maxAxisLabels = FrostedChartTokens.axisLabelBudget,
    this.onColumnTap,
    super.key,
  });

  final List<FrostedColumnData> columns;
  final double height;
  final Color? trackColor;
  final Color? fillColor;
  final TextStyle? labelStyle;
  final int maxAxisLabels;
  final ValueChanged<int>? onColumnTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double scale = _scale();
    final bool hasLabels = columns.any(
      (FrostedColumnData column) => column.label.isNotEmpty,
    );

    return Column(
      children: <Widget>[
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (int index = 0; index < columns.length; index++)
                Expanded(
                  child: _Column(
                    data: columns[index],
                    scale: scale,
                    trackColor: trackColor ?? cs.primaryContainer,
                    fillColor: fillColor ?? cs.primary,
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
    for (final FrostedColumnData column in columns) {
      if (column.value > scale) scale = column.value;
    }
    return scale;
  }

  String _tick(int index) {
    final bool kept = (columns.length - 1 - index).isEven;
    if (columns.length > maxAxisLabels && !kept) return '';
    return columns[index].label;
  }
}

class _Column extends StatelessWidget {
  const _Column({
    required this.data,
    required this.scale,
    required this.trackColor,
    required this.fillColor,
    required this.onTap,
  });

  final FrostedColumnData data;
  final double scale;
  final Color trackColor;
  final Color fillColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final double factor = scale <= 0 ? 0 : data.value / scale;
    final Widget column = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FrostedChartTokens.columnGap / 2,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: factor.clamp(FrostedChartTokens.columnMinFactor, 1.0),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(FrostedChartTokens.columnTopRadius),
              bottom: Radius.circular(FrostedChartTokens.columnBottomRadius),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ColoredBox(color: trackColor),
                if (data.value > 0)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      widthFactor: 1,
                      heightFactor: (data.fill / data.value).clamp(0.0, 1.0),
                      child: ColoredBox(color: fillColor),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (onTap == null) return column;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: column,
    );
  }
}
