import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/data/service/category_display_resolver.dart';
import 'package:mybudget/ui/capture/models/journal_entry.dart';

class DayGauge extends StatelessWidget {
  const DayGauge({required this.segments, super.key});
  static const double thickness = 4;
  static const double gap = 3;
  static const int maxSegments = 5;

  final List<FrostedBarSegment> segments;

  static List<FrostedBarSegment> segmentsForDay(
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
      for (final weight in sorted.take(maxSegments))
        FrostedBarSegment(value: weight.value, color: Color(weight.key)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FrostedStackedBar(
      segments: segments,
      thickness: thickness,
      gap: gap,
      animated: true,
    );
  }
}
