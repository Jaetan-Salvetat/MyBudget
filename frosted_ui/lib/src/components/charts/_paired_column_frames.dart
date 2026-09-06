import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'frosted_paired_column_chart.dart';

@immutable
class PairedColumnFrame {
  const PairedColumnFrame({
    required this.primary,
    required this.secondary,
    required this.weight,
    required this.label,
  });

  final double primary;
  final double secondary;
  final double weight;
  final String label;

  static PairedColumnFrame lerp(
    PairedColumnFrame? from,
    PairedColumnFrame? to,
    double t,
  ) {
    final PairedColumnFrame held = (to ?? from)!;

    return PairedColumnFrame(
      primary: _lerp(from?.primary ?? held.primary, held.primary, t),
      secondary: _lerp(from?.secondary ?? held.secondary, held.secondary, t),
      weight: _lerp(from?.weight ?? 0, to?.weight ?? 0, t),
      label: held.label,
    );
  }

  static double _lerp(double from, double to, double t) =>
      from + (to - from) * t;

  @override
  bool operator ==(Object other) =>
      other is PairedColumnFrame &&
      other.primary == primary &&
      other.secondary == secondary &&
      other.weight == weight &&
      other.label == label;

  @override
  int get hashCode => Object.hash(primary, secondary, weight, label);
}

@immutable
class PairedColumnFrames {
  const PairedColumnFrames(this.frames);

  factory PairedColumnFrames.of(
    List<FrostedPairedColumnData> columns, {
    required int maxAxisLabels,
  }) {
    double peak = 0;
    for (final FrostedPairedColumnData column in columns) {
      peak = math.max(peak, math.max(column.primary, column.secondary));
    }

    return PairedColumnFrames(<PairedColumnFrame>[
      for (int index = 0; index < columns.length; index++)
        PairedColumnFrame(
          primary: peak <= 0 ? 0 : columns[index].primary / peak,
          secondary: peak <= 0 ? 0 : columns[index].secondary / peak,
          weight: 1,
          label: _tickIn(columns, index, maxAxisLabels),
        ),
    ]);
  }

  static String _tickIn(
    List<FrostedPairedColumnData> columns,
    int index,
    int maxAxisLabels,
  ) {
    final bool kept = (columns.length - 1 - index).isEven;
    if (columns.length > maxAxisLabels && !kept) return '';
    return columns[index].label;
  }

  final List<PairedColumnFrame> frames;

  int get length => frames.length;
  PairedColumnFrame operator [](int index) => frames[index];
  Iterable<T> map<T>(T Function(PairedColumnFrame) toElement) =>
      frames.map(toElement);
  bool every(bool Function(PairedColumnFrame) test) => frames.every(test);
  bool any(bool Function(PairedColumnFrame) test) => frames.any(test);

  static PairedColumnFrames lerp(
    PairedColumnFrames from,
    PairedColumnFrames to,
    double t,
  ) {
    if (t <= 0) return from;
    if (t >= 1) return to;

    final int count = math.max(from.length, to.length);

    return PairedColumnFrames(<PairedColumnFrame>[
      for (int index = 0; index < count; index++)
        PairedColumnFrame.lerp(
          from._fromEnd(count - 1 - index),
          to._fromEnd(count - 1 - index),
          t,
        ),
    ]);
  }

  PairedColumnFrame? _fromEnd(int offset) =>
      offset < length ? frames[length - 1 - offset] : null;

  @override
  bool operator ==(Object other) =>
      other is PairedColumnFrames && listEquals(other.frames, frames);

  @override
  int get hashCode => Object.hashAll(frames);
}

class PairedColumnFramesTween extends Tween<PairedColumnFrames> {
  PairedColumnFramesTween({super.end});

  @override
  PairedColumnFrames lerp(double t) => PairedColumnFrames.lerp(begin!, end!, t);
}
