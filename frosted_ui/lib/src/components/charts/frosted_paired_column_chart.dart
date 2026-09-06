import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_chart_tokens.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import '_paired_column_frames.dart';

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
    this.animated = false,
    this.onColumnTap,
    super.key,
  });

  static const double _labelRevealPoint = 0.5;

  static const double _maxSlotWidth =
      FrostedChartTokens.columnMaxBarWidth * 2 +
      FrostedChartTokens.barGap +
      FrostedChartTokens.columnGap;

  final List<FrostedPairedColumnData> columns;
  final double height;
  final Color? primaryColor;
  final Color? secondaryColor;
  final TextStyle? labelStyle;
  final int maxAxisLabels;
  final bool animated;
  final ValueChanged<int>? onColumnTap;

  @override
  Widget build(BuildContext context) {
    final PairedColumnFrames frames = PairedColumnFrames.of(
      columns,
      maxAxisLabels: maxAxisLabels,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (!animated) return _chart(context, frames, constraints.maxWidth);

        final FrostedMotion motion = context.frostedTokens.motion.fluid;
        return TweenAnimationBuilder<PairedColumnFrames>(
          tween: PairedColumnFramesTween(end: frames),
          duration: motion.duration,
          curve: motion.curve,
          builder:
              (BuildContext context, PairedColumnFrames value, Widget? child) =>
                  _chart(context, value, constraints.maxWidth),
        );
      },
    );
  }

  Widget _chart(
    BuildContext context,
    PairedColumnFrames frames,
    double maxWidth,
  ) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<double> widths = _widthsIn(frames, maxWidth);
    final bool hasLabels = frames.any(
      (PairedColumnFrame frame) => frame.label.isNotEmpty,
    );

    return Column(
      children: <Widget>[
        SizedBox(
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int index = 0; index < frames.length; index++)
                SizedBox(
                  width: widths[index],
                  child: Opacity(
                    opacity: frames[index].weight.clamp(0.0, 1.0),
                    child: _Pair(
                      frame: frames[index],
                      width: widths[index],
                      primaryColor: primaryColor ?? cs.primaryContainer,
                      secondaryColor: secondaryColor ?? cs.primary,
                      onTap: onColumnTap == null
                          ? null
                          : () => onColumnTap!(index),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (hasLabels) ...<Widget>[
          const SizedBox(height: FrostedChartTokens.axisGap),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int index = 0; index < frames.length; index++)
                SizedBox(
                  width: widths[index],
                  child: Opacity(
                    opacity: _labelOpacityOf(frames[index].weight),
                    child: Text(
                      frames[index].label,
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
                ),
            ],
          ),
        ],
      ],
    );
  }

  List<double> _widthsIn(PairedColumnFrames frames, double maxWidth) {
    final double total = frames.frames.fold(
      0,
      (double sum, PairedColumnFrame frame) => sum + frame.weight,
    );
    if (total <= 0) {
      return List<double>.filled(frames.length, 0);
    }

    final double slot = math.min(maxWidth / total, _maxSlotWidth);
    return <double>[
      for (final PairedColumnFrame frame in frames.frames) slot * frame.weight,
    ];
  }

  double _labelOpacityOf(double weight) =>
      ((weight - _labelRevealPoint) / (1 - _labelRevealPoint)).clamp(0.0, 1.0);
}

class _Pair extends StatelessWidget {
  const _Pair({
    required this.frame,
    required this.width,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onTap,
  });

  final PairedColumnFrame frame;
  final double width;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final double barWidth =
        (width - FrostedChartTokens.columnGap - FrostedChartTokens.barGap) / 2;
    if (barWidth <= 0) return SizedBox(width: width);

    final Widget pair = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FrostedChartTokens.columnGap / 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: barWidth,
            child: _Bar(factor: frame.primary, color: primaryColor),
          ),
          const SizedBox(width: FrostedChartTokens.barGap),
          SizedBox(
            width: barWidth,
            child: _Bar(factor: frame.secondary, color: secondaryColor),
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
