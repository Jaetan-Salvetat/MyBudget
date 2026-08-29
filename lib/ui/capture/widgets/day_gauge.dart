import 'package:material_ui/material_ui.dart';
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
    final total = segments.fold(0.0, (sum, segment) => sum + segment.weight);
    if (total <= 0) return const SizedBox(height: height);

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final free =
              constraints.maxWidth - gap * (segments.length - 1);
          return Row(
            children: [
              for (var index = 0; index < segments.length; index++) ...[
                if (index > 0) const SizedBox(width: gap),
                AnimatedContainer(
                  duration: motion.duration,
                  curve: motion.curve,
                  width: free * (segments[index].weight / total),
                  decoration: BoxDecoration(
                    color: segments[index].color,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
