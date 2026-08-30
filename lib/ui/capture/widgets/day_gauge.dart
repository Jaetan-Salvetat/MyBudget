import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/ui/capture/models/journal_entry.dart';

class GaugeSegment {
  final Color color;
  final double weight;

  const GaugeSegment({required this.color, required this.weight});

  /// One segment per category the day spent on, heaviest first. Revenues are
  /// left out : the gauge reads what the day cost.
  static List<GaugeSegment> forDay(
    List<JournalEntry> entries,
    CategoryDisplayResolver? resolver,
    Color fallback,
  ) {
    final weights = <int, double>{};

    for (final entry in entries) {
      if (entry.isIncome) continue;
      final slug = entry.categorySlug;
      final display = slug == null ? null : resolver?.resolve(slug);
      final color = display?.color ?? fallback.toARGB32();
      weights.update(
        color,
        (weight) => weight + entry.amount,
        ifAbsent: () => entry.amount,
      );
    }

    final sorted = weights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return [
      for (final weight in sorted.take(DayGauge.maxSegments))
        GaugeSegment(color: Color(weight.key), weight: weight.value),
    ];
  }
}

/// The day summed up in colour : four pixels that shift the moment a
/// transaction lands, without a single figure changing size.
class DayGauge extends StatelessWidget {
  static const double height = 4;
  static const double gap = 3;
  static const int maxSegments = 5;

  final List<GaugeSegment> segments;

  const DayGauge({required this.segments, super.key});

  @override
  Widget build(BuildContext context) {
    final motion = context.frostedTokens.motion.fluid;
    final bars = _GaugeBars.of(segments);
    if (bars.isEmpty) return const SizedBox(height: height);

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return TweenAnimationBuilder<_GaugeBars>(
            tween: _GaugeBarsTween(end: bars),
            duration: motion.duration,
            curve: motion.curve,
            builder: (context, bars, child) =>
                _bars(bars, constraints.maxWidth),
          );
        },
      ),
    );
  }

  /// Every bar is a share of the same width, so the row always fits : a shape
  /// changing mid-animation cannot make the segments sum to more than the day.
  Widget _bars(_GaugeBars bars, double maxWidth) {
    final free = maxWidth - gap * (bars.length - 1);

    return Row(
      children: [
        for (var index = 0; index < bars.length; index++) ...[
          if (index > 0) const SizedBox(width: gap),
          Container(
            width: free * bars[index].fraction,
            decoration: BoxDecoration(
              color: bars[index].color,
              borderRadius: BorderRadius.circular(height),
            ),
          ),
        ],
      ],
    );
  }
}

/// One drawn bar : a colour and the share of the width it takes.
@immutable
class _GaugeBar {
  final Color color;
  final double fraction;

  const _GaugeBar({required this.color, required this.fraction});

  static _GaugeBar lerp(_GaugeBar? from, _GaugeBar? to, double t) {
    final color = Color.lerp(from?.color, to?.color, t);
    final start = from?.fraction ?? 0;
    final end = to?.fraction ?? 0;

    return _GaugeBar(
      color: color ?? (to ?? from!).color,
      fraction: start + (end - start) * t,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _GaugeBar && other.color == color && other.fraction == fraction;

  @override
  int get hashCode => Object.hash(color, fraction);
}

/// The bars of one gauge, weights already turned into shares summing to one.
@immutable
class _GaugeBars {
  final List<_GaugeBar> bars;

  const _GaugeBars(this.bars);

  static _GaugeBars of(List<GaugeSegment> segments) {
    final total = segments.fold(0.0, (sum, segment) => sum + segment.weight);
    if (total <= 0) return const _GaugeBars([]);

    return _GaugeBars([
      for (final segment in segments)
        _GaugeBar(
          color: segment.color,
          fraction: math.max(segment.weight, 0) / total,
        ),
    ]);
  }

  bool get isEmpty => bars.isEmpty;
  int get length => bars.length;
  _GaugeBar operator [](int index) => bars[index];

  /// Bars are paired by rank ; a rank the other side lacks fades in or out on
  /// a zero share rather than shifting the ones that stay.
  static _GaugeBars lerp(_GaugeBars from, _GaugeBars to, double t) {
    final count = math.max(from.length, to.length);

    return _GaugeBars([
      for (var index = 0; index < count; index++)
        _GaugeBar.lerp(
          index < from.length ? from[index] : null,
          index < to.length ? to[index] : null,
          t,
        ),
    ]);
  }

  @override
  bool operator ==(Object other) =>
      other is _GaugeBars && listEquals(other.bars, bars);

  @override
  int get hashCode => Object.hashAll(bars);
}

class _GaugeBarsTween extends Tween<_GaugeBars> {
  _GaugeBarsTween({super.end});

  @override
  _GaugeBars lerp(double t) => _GaugeBars.lerp(begin!, end!, t);
}
