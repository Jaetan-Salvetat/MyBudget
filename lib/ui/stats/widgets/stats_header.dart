import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/constants/layout_insets.dart';
import 'package:mybudget/ui/stats/models/stats_range.dart';
import 'package:mybudget/ui/stats/stats_provider.dart';

class StatsHeader extends ConsumerWidget {
  static const double segmentWidth = 88;

  const StatsHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(statsRangeProvider);

    return Padding(
      padding: kMainFlowTopBarPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Stats',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.8,
            ),
          ),
          FrostedSegmentedControl(
            segments: [for (final value in StatsRange.values) value.label],
            currentIndex: range.index,
            segmentWidth: segmentWidth,
            onTap: (index) => ref
                .read(statsRangeProvider.notifier)
                .select(StatsRange.values[index]),
          ),
        ],
      ),
    );
  }
}
