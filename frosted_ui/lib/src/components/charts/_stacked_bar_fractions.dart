import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'frosted_bar_segment.dart';

@immutable
class StackedBarFraction {
  const StackedBarFraction({required this.color, required this.fraction});

  final Color color;
  final double fraction;

  static StackedBarFraction lerp(
    StackedBarFraction? from,
    StackedBarFraction? to,
    double t,
  ) {
    final Color? color = Color.lerp(from?.color, to?.color, t);
    final double start = from?.fraction ?? 0;
    final double end = to?.fraction ?? 0;

    return StackedBarFraction(
      color: color ?? (to ?? from!).color,
      fraction: start + (end - start) * t,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StackedBarFraction &&
      other.color == color &&
      other.fraction == fraction;

  @override
  int get hashCode => Object.hash(color, fraction);
}

@immutable
class StackedBarFractions {
  const StackedBarFractions(this.bars);

  factory StackedBarFractions.of(List<FrostedBarSegment> segments) {
    final List<FrostedBarSegment> weighted = segments
        .where((FrostedBarSegment segment) => segment.value > 0)
        .toList();
    final double total = weighted.fold(
      0,
      (double sum, FrostedBarSegment segment) => sum + segment.value,
    );
    if (total <= 0) return const StackedBarFractions(<StackedBarFraction>[]);

    return StackedBarFractions(<StackedBarFraction>[
      for (final FrostedBarSegment segment in weighted)
        StackedBarFraction(
          color: segment.color,
          fraction: segment.value / total,
        ),
    ]);
  }

  final List<StackedBarFraction> bars;

  bool get isEmpty => bars.isEmpty;
  int get length => bars.length;
  StackedBarFraction operator [](int index) => bars[index];

  static StackedBarFractions lerp(
    StackedBarFractions from,
    StackedBarFractions to,
    double t,
  ) {
    final int count = math.max(from.length, to.length);

    return StackedBarFractions(<StackedBarFraction>[
      for (int index = 0; index < count; index++)
        StackedBarFraction.lerp(
          index < from.length ? from[index] : null,
          index < to.length ? to[index] : null,
          t,
        ),
    ]);
  }

  @override
  bool operator ==(Object other) =>
      other is StackedBarFractions && listEquals(other.bars, bars);

  @override
  int get hashCode => Object.hashAll(bars);
}

class StackedBarFractionsTween extends Tween<StackedBarFractions> {
  StackedBarFractionsTween({super.end});

  @override
  StackedBarFractions lerp(double t) =>
      StackedBarFractions.lerp(begin!, end!, t);
}
